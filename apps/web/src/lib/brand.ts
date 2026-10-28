/**
 * The VarsityKotha mark: ক (Baloo Da 2 ExtraBold, as outlines) in a speech
 * bubble on a teal tile. Coordinates are on a 1024 x 1024 artboard, the
 * same as the app icon (assets/icon/ at the repo root).
 */
export const brandPaths = {
  bubble: "M 396 238 H 628 C 732.5 238 818 323.5 818 428 V 500 C 818 604.5 732.5 690 628 690 H 448 C 378 698 306 772 250 810 C 234 820 222 806 230 790 C 258 746 270 680 254 638 C 228.8 610.2 206 557 206 500 V 428 C 206 323.5 291.5 238 396 238 Z",
  ka: "M605.3 541.1Q588.9 541.1 579.9 531.9Q570.9 522.7 570.9 509.1Q570.9 503.5 572.3 498.2Q573.7 492.8 575.3 490L581.3 490Q586.9 490 591.7 486.4Q596.5 482.8 596.5 473.6Q596.5 463.6 586.5 456Q576.9 448.8 552.1 446.8L552.1 590.2Q547.7 595 539.2 598Q530.6 601 517.8 601Q515 601 512.6 600.6Q510.2 600.2 508.6 599.8Q484.2 581.4 463.1 567.7Q441.9 553.9 419.7 541.9Q397.6 529.9 369.2 517.1Q362.8 507.9 359.6 494.4Q356.4 480.8 356.4 467.6Q356.4 464.4 356.6 461.8Q356.8 459.2 357.2 457.6Q376.4 444 399 432.5Q421.5 420.9 445.3 411.5Q469.1 402.1 491.4 396.1L491.4 386.1L350.4 386.1Q341.3 386.1 335.5 380.5Q329.7 374.9 329.7 362.2Q329.7 355 331.7 349Q333.7 343 335.7 339L673.6 339Q682.7 339 688.5 344.6Q694.3 350.2 694.3 363Q694.3 370.2 692.3 376.1Q690.3 382.1 688.3 386.1L552.1 386.1L552.1 396.9Q579.3 397.3 602.9 405.3Q628 414.1 643.8 431.9Q659.6 449.6 659.6 477.6Q659.6 499.2 651.4 513.3Q643.2 527.5 630.6 534.3Q618 541.1 605.3 541.1ZM490.6 452Q471.5 456.8 454.1 465Q436.7 473.2 423.9 482Q433.5 486.8 444.9 493.2Q456.3 499.6 468.5 506.9Q480.6 514.3 492.2 522.7Q491.8 515.5 491.4 507.9Q491 500.4 490.8 493Q490.6 485.6 490.6 480Z",
} as const;

export const brandColors = {
  tileFrom: "#2DD4BF",
  tileVia: "#0F9488",
  tileTo: "#0B5E57",
  ink: "#0B5E57",
} as const;

/** The full rounded icon as an SVG string (for images such as the share card). */
export const brandIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><defs><linearGradient id="bg" x1="0.15" y1="0" x2="0.85" y2="1"><stop offset="0" stop-color="${brandColors.tileFrom}"/><stop offset="0.48" stop-color="${brandColors.tileVia}"/><stop offset="1" stop-color="${brandColors.tileTo}"/></linearGradient></defs><rect width="1024" height="1024" rx="232" fill="url(#bg)"/><path d="${brandPaths.bubble}" fill="#fff"/><path d="${brandPaths.ka}" fill="${brandColors.ink}"/></svg>`;
