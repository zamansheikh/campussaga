"use client";

import { Printer } from "lucide-react";

import { Button } from "@/components/ui/button";

/** Opens the browser's print dialog, where "Save as PDF" makes the file for the sponsor. */
export function PrintButton() {
  return (
    <Button onClick={() => window.print()}>
      <Printer /> Print or save as PDF
    </Button>
  );
}
