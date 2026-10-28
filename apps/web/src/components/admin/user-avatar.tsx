import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { cn } from "@/lib/utils";

export function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  return ((parts[0]?.[0] ?? "") + (parts.length > 1 ? (parts.at(-1)?.[0] ?? "") : "")).toUpperCase();
}

type Who = {
  id: string;
  email: string;
  displayName: string | null;
  photoVersion?: string | null;
  googlePhotoUrl?: string | null;
};

/** A user's photo (uploaded, else Google), else their initials. */
export function UserAvatar({ user, className, textClassName }: { user: Who; className?: string; textClassName?: string }) {
  const src = user.photoVersion
    ? `/admin/photo/${user.id}?v=${encodeURIComponent(user.photoVersion)}`
    : (user.googlePhotoUrl ?? undefined);
  return (
    <Avatar className={className}>
      {src ? <AvatarImage src={src} alt="" referrerPolicy="no-referrer" className="object-cover" /> : null}
      <AvatarFallback className={cn("bg-primary-soft font-semibold text-primary-soft-foreground", textClassName)}>
        {initials(user.displayName || user.email)}
      </AvatarFallback>
    </Avatar>
  );
}
