# ============================================================================
# Makefile - Calculadora de Punto Flotante para Monitor 6502
# ============================================================================
# Uso:
#   make        - Compilar el programa
#   make clean  - Limpiar archivos generados
#   make info   - Ver tamaño del binario
#   make map    - Ver mapa de memoria
#
# NOTA: Este makefile usa sintaxis POSIX (compatible con sh/bash/mingw32-make).
#       No usa "if not exist" ni rutas con "\" para que funcione tanto en
#       Git Bash / MSYS2 como en WSL.
# ============================================================================

# Configuración CC65 (sobrescribir con: make CC65_HOME=/ruta/a/cc65)
# Se usa formato D:/... para que las herramientas nativas de Windows (ld65)
# puedan abrir la ruta, ya que no entienden el formato POSIX /d/...
CC65_HOME ?= D:/cc65

# Herramientas
CC = cl65
CA65 = ca65
LD = ld65

# Directorios
SRC_DIR = src
CONFIG_DIR = config
BUILD_DIR = build
OUTPUT_DIR = output
LIB_DIR = ../libs

# Configuración del linker
LD_CONFIG = $(CONFIG_DIR)/programa.cfg

# ============================================
# LIBRERÍAS (agregar más aquí)
# ============================================
TM1638_DIR = $(LIB_DIR)/tm1638-6502-cc65
MSBASIC_FLOAT_DIR = libs/msbasic-float
MSBASIC_DIR = $(MSBASIC_FLOAT_DIR)/msbasic

INCLUDES = -I$(TM1638_DIR)/include -I$(MSBASIC_FLOAT_DIR)/include -I$(SRC_DIR) -Iinclude

# Nombre del programa
PROGRAM_NAME = calc-float

# Archivos de salida
PROGRAM = $(OUTPUT_DIR)/$(PROGRAM_NAME).bin
MAP_FILE = $(OUTPUT_DIR)/$(PROGRAM_NAME).map

# Archivos objeto
C_OBJECTS = $(BUILD_DIR)/main.o $(BUILD_DIR)/float_convert.o
ASM_OBJECTS = $(BUILD_DIR)/startup.o $(BUILD_DIR)/msbasic_wrapper.o $(BUILD_DIR)/msbasic_float_only.o
TM1638_OBJ = $(BUILD_DIR)/tm1638.o

OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS) $(TM1638_OBJ)

# Flags del compilador C
CFLAGS = $(INCLUDES) -O --cpu 6502

# Flags del ensamblador
ASFLAGS = --cpu 6502

# Flags para MSBasic (requiere definir la configuración)
MSBASIC_ASFLAGS = --cpu 6502 --feature force_range -D CONFIG_2 -I$(MSBASIC_DIR)

# Flags del linker
LDFLAGS = -C $(LD_CONFIG) -m $(MAP_FILE)

# Librería del runtime C de CC65
CC65_LIB = $(CC65_HOME)/lib/none.lib

# ============================================================================
# REGLAS PRINCIPALES
# ============================================================================

all: dirs $(PROGRAM)
	@echo "========================================"
	@echo "Programa generado: $(PROGRAM)"
	@printf "Tamano: %s bytes\n" "`wc -c < $(PROGRAM)`"
	@echo "========================================"
	@echo "Para usar:"
	@echo "  1. Copiar a SD como CALC"
	@echo "  2. En el monitor:"
	@echo "     LOAD CALC 0800"
	@echo "     R 0800"
	@echo "========================================"

dirs:
	@mkdir -p "$(BUILD_DIR)" "$(OUTPUT_DIR)"

# Compilar C
$(BUILD_DIR)/main.o: $(SRC_DIR)/main.c | dirs
	$(CC) -c $(CFLAGS) -o $@ $<

$(BUILD_DIR)/float_convert.o: $(MSBASIC_FLOAT_DIR)/src/float_convert.c | dirs
	$(CC) -c $(CFLAGS) -o $@ $<

# Compilar TM1638
$(TM1638_OBJ): $(TM1638_DIR)/src/tm1638.c | dirs
	$(CC) -c $(CFLAGS) -o $@ $<

# Ensamblar startup
$(BUILD_DIR)/startup.o: $(SRC_DIR)/startup.s | dirs
	$(CA65) $(ASFLAGS) -o $@ $<

# Ensamblar wrapper MSBasic
$(BUILD_DIR)/msbasic_wrapper.o: $(MSBASIC_FLOAT_DIR)/src/msbasic_wrapper.s | dirs
	$(CA65) $(ASFLAGS) -I$(MSBASIC_DIR) -o $@ $<

# Ensamblar módulo MSBasic completo
$(BUILD_DIR)/msbasic_float_only.o: $(MSBASIC_FLOAT_DIR)/src/msbasic_float_only.s | dirs
	$(CA65) $(MSBASIC_ASFLAGS) -o $@ $<

# Linkar
$(PROGRAM): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS) $(CC65_LIB)

# ============================================================================
# UTILIDADES
# ============================================================================

info:
	@echo "========================================"
	@echo "Informacion del programa"
	@echo "========================================"
	@if [ -f $(PROGRAM) ]; then \
		printf "Tamano: %s bytes\n" "`wc -c < $(PROGRAM)`"; \
	else \
		echo "Error: Programa no compilado"; \
	fi

map:
	@if [ -f $(MAP_FILE) ]; then cat $(MAP_FILE); else echo "Error: Archivo de mapa no encontrado. Compilar primero."; fi

clean:
	@rm -rf "$(BUILD_DIR)" "$(OUTPUT_DIR)"
	@echo "Limpieza completa"

# ============================================================================
# AYUDA
# ============================================================================

help:
	@echo "Uso del makefile:"
	@echo "  make        - Compilar el programa"
	@echo "  make clean  - Limpiar archivos generados"
	@echo "  make info   - Ver informacion del binario"
	@echo "  make map    - Ver mapa de memoria"

.PHONY: all dirs clean info map help
