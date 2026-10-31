package sponsors

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
)

// AdminSponsor is a sponsor for the admin panel.
type AdminSponsor struct {
	ID           uuid.UUID  `json:"id"`
	Name         string     `json:"name"`
	Category     string     `json:"category"`
	LogoURL      *string    `json:"logoUrl"`
	Website      string     `json:"website"`
	ContactName  string     `json:"contactName"`
	ContactPhone string     `json:"contactPhone"`
	ContactEmail string     `json:"contactEmail"`
	Notes        string     `json:"notes"`
	ArchivedAt   *time.Time `json:"archivedAt"`
	CreatedAt    time.Time  `json:"createdAt"`
	UpdatedAt    time.Time  `json:"updatedAt"`
	// Promos: how many ads it has, and how many are live now.
	Promos SponsorPromoCounts `json:"promos"`
}

type SponsorPromoCounts struct {
	Live  int `json:"live"`
	Total int `json:"total"`
}

func (x sponsor) admin(counts SponsorPromoCounts) AdminSponsor {
	return AdminSponsor{
		ID: x.ID, Name: x.Name, Category: x.Category, LogoURL: logoURL(x.ID, x.LogoKey, x.LogoVersion),
		Website: x.Website, ContactName: x.ContactName, ContactPhone: x.ContactPhone, ContactEmail: x.ContactEmail,
		Notes: x.Notes, ArchivedAt: utcPtr(x.ArchivedAt), CreatedAt: x.CreatedAt.UTC(), UpdatedAt: x.UpdatedAt.UTC(),
		Promos: counts,
	}
}

func utcPtr(t *time.Time) *time.Time {
	if t == nil {
		return nil
	}
	u := t.UTC()
	return &u
}

// promoCountsSQL: live (serving now) and total ads of sponsor $1.
const promoCountsSQL = `SELECT count(*) FILTER (WHERE status = 'live' AND starts_at <= $2 AND ends_at > $2)::int, count(*)::int
	FROM promos WHERE sponsor_id = $1`

func (s *Service) sponsorView(ctx context.Context, x sponsor) (*AdminSponsor, error) {
	var c SponsorPromoCounts
	if err := s.d.Q(ctx).QueryRow(ctx, promoCountsSQL, x.ID, s.now()).Scan(&c.Live, &c.Total); err != nil {
		return nil, err
	}
	v := x.admin(c)
	return &v, nil
}

// ---- list ---------------------------------------------------------------------------

type sponsorListReq struct {
	Page     string `json:"-" query:"page" validate:"omitempty,number,min=1,max=1000"`
	PageSize string `json:"-" query:"pageSize" validate:"omitempty,number"`
	Q        string `json:"-" query:"q" validate:"max=80"`
	// Archived: "true" lists archived sponsors only; anything else, the rest.
	Archived string `json:"-" query:"archived" validate:"omitempty,oneof=true false"`
}

func (s *Service) handleAdminSponsors(ctx context.Context, in *sponsorListReq) (*Page[AdminSponsor], error) {
	page, size := pageOf(in.Page, in.PageSize)
	archived := in.Archived == "true"
	q := strings.TrimSpace(in.Q)
	where := `(s.archived_at IS NOT NULL) = $1 AND ($2 = '' OR s.name ILIKE '%' || $2 || '%' OR s.contact_name ILIKE '%' || $2 || '%')`
	out := &Page[AdminSponsor]{Items: []AdminSponsor{}, Page: page, PageSize: size}
	dq := s.d.Q(ctx)
	if err := dq.QueryRow(ctx, `SELECT count(*)::int FROM sponsors s WHERE `+where, archived, q).Scan(&out.Total); err != nil {
		return nil, err
	}
	rows, err := dq.Query(ctx, `SELECT `+sponsorCols+`,
			(SELECT count(*) FROM promos p WHERE p.sponsor_id = s.id AND p.status = 'live' AND p.starts_at <= $5 AND p.ends_at > $5)::int,
			(SELECT count(*) FROM promos p WHERE p.sponsor_id = s.id)::int
		FROM sponsors s WHERE `+where+` ORDER BY lower(s.name), s.id LIMIT $3 OFFSET $4`,
		archived, q, size, (page-1)*size, s.now())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var x sponsor
		var c SponsorPromoCounts
		if err := rows.Scan(&x.ID, &x.Name, &x.Category, &x.LogoKey, &x.LogoVersion, &x.Website, &x.ContactName, &x.ContactPhone,
			&x.ContactEmail, &x.Notes, &x.ArchivedAt, &x.CreatedAt, &x.UpdatedAt, &c.Live, &c.Total); err != nil {
			return nil, err
		}
		out.Items = append(out.Items, x.admin(c))
	}
	return out, rows.Err()
}

type sponsorReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleAdminSponsor(ctx context.Context, in *sponsorReq) (*AdminSponsor, error) {
	x, err := s.loadSponsor(ctx, uuid.MustParse(in.ID), false)
	if err != nil {
		return nil, err
	}
	return s.sponsorView(ctx, x)
}

// ---- create and edit ----------------------------------------------------------------

type sponsorInput struct {
	ID           string  `json:"-" path:"id" validate:"omitempty,uuid"`
	Name         *string `json:"name" validate:"omitnil,max=80"`
	Category     *string `json:"category" validate:"omitnil,oneof=general health"`
	Website      *string `json:"website" validate:"omitnil,max=300"`
	ContactName  *string `json:"contactName" validate:"omitnil,max=80"`
	ContactPhone *string `json:"contactPhone" validate:"omitnil,max=20"`
	ContactEmail *string `json:"contactEmail" validate:"omitnil,max=120"`
	Notes        *string `json:"notes" validate:"omitnil,max=1000"`
	// Archived (PATCH only): false brings an archived sponsor back.
	Archived *bool `json:"archived"`
}

// apply copies the set fields onto x and checks them.
func (in *sponsorInput) apply(x *sponsor) error {
	trim := func(p *string) string { return strings.TrimSpace(*p) }
	if in.Name != nil {
		x.Name = trim(in.Name)
	}
	if in.Category != nil {
		x.Category = *in.Category
	}
	if in.Website != nil {
		x.Website = trim(in.Website)
	}
	if in.ContactName != nil {
		x.ContactName = trim(in.ContactName)
	}
	if in.ContactPhone != nil {
		x.ContactPhone = trim(in.ContactPhone)
	}
	if in.ContactEmail != nil {
		x.ContactEmail = trim(in.ContactEmail)
	}
	if in.Notes != nil {
		x.Notes = trim(in.Notes)
	}
	if x.Name == "" {
		return invalid("name", "is required")
	}
	if x.Website != "" && !validWebLink(x.Website) {
		return invalid("website", "must be an https:// address")
	}
	if x.ContactEmail != "" && !emailRe.MatchString(x.ContactEmail) {
		return invalid("contactEmail", "must be a valid email address")
	}
	return nil
}

func (s *Service) handleAdminSponsorCreate(ctx context.Context, in *sponsorInput) (*AdminSponsor, error) {
	if in.Archived != nil {
		return nil, invalid("archived", "can't be set on a new sponsor")
	}
	x := sponsor{Category: "general"}
	if err := in.apply(&x); err != nil {
		return nil, err
	}
	var out *AdminSponsor
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		now := s.now()
		row := s.d.Q(ctx).QueryRow(ctx, `INSERT INTO sponsors (name, category, website, contact_name, contact_phone, contact_email, notes,
				created_by, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9) RETURNING `+strings.ReplaceAll(sponsorCols, "s.", ""),
			x.Name, x.Category, x.Website, x.ContactName, x.ContactPhone, x.ContactEmail, x.Notes, auth.MustUser(ctx).UserID, now)
		created, err := scanSponsor(row)
		if err != nil {
			return err
		}
		if out, err = s.sponsorView(ctx, created); err != nil {
			return err
		}
		return s.audit(ctx, "sponsor.create", "sponsor", created.ID.String(), map[string]any{"name": created.Name})
	})
	return out, err
}

func (s *Service) handleAdminSponsorPatch(ctx context.Context, in *sponsorInput) (*AdminSponsor, error) {
	id, err := uuid.Parse(in.ID)
	if err != nil {
		return nil, ErrSponsorNotFound
	}
	var out *AdminSponsor
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		x, err := s.loadSponsor(ctx, id, true)
		if err != nil {
			return err
		}
		wasHealth := x.Category == "health"
		if err := in.apply(&x); err != nil {
			return err
		}
		// The Blood page only shows health sponsors: no switching away while
		// one of its Blood ads could still run.
		if wasHealth && x.Category != "health" {
			var n int
			if err := s.d.Q(ctx).QueryRow(ctx, `SELECT count(*)::int FROM promos WHERE sponsor_id = $1 AND placement = 'line:blood'
				AND status IN ('live', 'paused')`, id).Scan(&n); err != nil {
				return err
			}
			if n > 0 {
				return ErrHealthOnly.WithMessage("End this sponsor's Blood page ads before changing its category")
			}
		}
		now := s.now()
		action := "sponsor.update"
		if in.Archived != nil {
			switch {
			case *in.Archived && x.ArchivedAt == nil:
				x.ArchivedAt, action = &now, "sponsor.archive"
				if err := s.pauseLive(ctx, id); err != nil {
					return err
				}
			case !*in.Archived && x.ArchivedAt != nil:
				x.ArchivedAt, action = nil, "sponsor.restore"
			}
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE sponsors SET name = $2, category = $3, website = $4, contact_name = $5,
				contact_phone = $6, contact_email = $7, notes = $8, archived_at = $9, updated_at = $10 WHERE id = $1`,
			id, x.Name, x.Category, x.Website, x.ContactName, x.ContactPhone, x.ContactEmail, x.Notes, x.ArchivedAt, now); err != nil {
			return err
		}
		x.UpdatedAt = now
		if out, err = s.sponsorView(ctx, x); err != nil {
			return err
		}
		return s.audit(ctx, action, "sponsor", id.String(), map[string]any{"name": x.Name})
	})
	return out, err
}

// handleAdminSponsorArchive: DELETE archives the sponsor (reports stay) and
// pauses its live ads.
func (s *Service) handleAdminSponsorArchive(ctx context.Context, in *sponsorReq) (*AdminSponsor, error) {
	yes := true
	return s.handleAdminSponsorPatch(ctx, &sponsorInput{ID: in.ID, Archived: &yes})
}

// pauseLive pauses every live ad of a sponsor (it is being archived).
func (s *Service) pauseLive(ctx context.Context, sponsorID uuid.UUID) error {
	_, err := s.d.Q(ctx).Exec(ctx, `UPDATE promos SET status = 'paused', updated_at = $2 WHERE sponsor_id = $1 AND status = 'live'`,
		sponsorID, s.now())
	return err
}
