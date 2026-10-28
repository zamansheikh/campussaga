"use client";

import { Menu } from "lucide-react";
import { useState } from "react";

import { SidebarNav } from "@/components/admin/sidebar-nav";
import { BrandMark } from "@/components/site/brand-mark";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import type { PanelRole } from "@/lib/admin/types";

export function MobileNav({ role }: { role: PanelRole }) {
  const [open, setOpen] = useState(false);
  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button variant="ghost" size="icon" className="lg:hidden" aria-label="Open menu">
          <Menu className="size-5" />
        </Button>
      </SheetTrigger>
      <SheetContent side="left" className="w-72 bg-sidebar p-4">
        <SheetHeader className="mb-2 p-0">
          <SheetTitle className="flex items-center gap-2">
            <BrandMark /> VarsityKotha admin
          </SheetTitle>
        </SheetHeader>
        <SidebarNav role={role} onNavigate={() => setOpen(false)} />
      </SheetContent>
    </Sheet>
  );
}
