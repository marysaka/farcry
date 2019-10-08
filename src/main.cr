require "./gdt"

Logger.info "Welcome to FarCry"

Logger.debug "Setup GDT"
gdt = Pointer(GDT).new 0x800
gdt.value.setup_gdt
gdt.value.flush
Logger.debug "GDT Setup done"
