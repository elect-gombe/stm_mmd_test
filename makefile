
GCC_BIN = 
PROJECT = Test

#use debugger?
DEBUG = 1
APPDIR = ./
DRIVERSDIR = ./Drivers
HALDIR = $(DRIVERSDIR)/STM32F4xx_HAL_Driver
CMSISDIR = $(DRIVERSDIR)/CMSIS
CMSIS_DEVICEDIR = $(CMSISDIR)/Device/ST/STM32F4xx

OBJDIR=./obj

USR_SRCDIR = $(APPDIR)/Src
HAL_SRCDIR = $(HALDIR)/Src
STARTUP_SRC = ./startup/startup_stm32f446xx.s
STARTUP_OBJ = startup.o

BINDIR = ./bin

CSRCS   = 	\
		$(wildcard $(USR_SRCDIR)/*.c)	\
		$(wildcard $(HAL_SRCDIR)/*.c)
CPPSRCS	=	\
		$(wildcard $(USR_SRCDIR)/*.cpp)



SYS_OBJECTS = 	$(addprefix $(OBJDIR)/, $(notdir $(CSRCS:.c=.o)))\
		$(addprefix $(OBJDIR)/, $(notdir $(CPPSRCS:.cpp=.o)))\
		$(OBJDIR)/$(STARTUP_OBJ)

INCLUDEDIRS =   -I $(shell cd $(APPDIR)/Inc &&  pwd)							\
	 	-I $(shell cd  $(HALDIR)/Inc&& pwd)						\
		-I $(shell cd  $(CMSISDIR)/Inc&& pwd)						\
		-I $(shell cd  $(CMSIS_DEVICEDIR)/Inc&& pwd)

LINKER_SCRIPT = ./STM32F446RETx_FLASH.ld

CC      = $(GCC_BIN)arm-none-eabi-gcc
CPP     = $(GCC_BIN)arm-none-eabi-g++
LD      = $(GCC_BIN)arm-none-eabi-gcc
OBJCOPY = $(GCC_BIN)arm-none-eabi-objcopy
OBJDUMP = $(GCC_BIN)arm-none-eabi-objdump
SIZE    = $(GCC_BIN)arm-none-eabi-size 

CPU = -mcpu=cortex-m4 -mthumb 

CC_FLAGS = $(CPU) -c -fno-common -fmessage-length=0 -Wall -Wextra -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer -MMD -MP

CC_SYMBOLS =  -DSTM32F446xx -std=c99 -mfloat-abi=softfp -mfpu=fpv4-sp-d16 -mcpu=cortex-m4 -march=armv7e-m -mtune=cortex-m4

LD_FLAGS = $(CPU) -Wl,--gc-sections --specs=nano.specs -Wl,-Map=$(BINDIR)/$(PROJECT).map,-cref -mcpu=cortex-m4 -march=armv7e-m -mthumb

LD_SYS_LIBS = -lgcc -lm -lc -fno-math-errno
#-lstdc++ -lsupc++ -lm -lc -lgcc -lnosys

ifeq ($(DEBUG), 1)
  CC_FLAGS += -DDEBUG -O3 -g3
else
  CC_FLAGS += -DNDEBUG -Os -g3
endif

.PHONY: all clean lst size disp openocd include

all: $(BINDIR)/$(PROJECT).bin $(BINDIR)/$(PROJECT).hex size

clean:
	rm -f $(PROJECT).bin $(PROJECT).elf $(PROJECT).hex $(PROJECT).map $(PROJECT).lst $(OBJDIR) $(BINDIR) -rf

$(OBJDIR)/$(STARTUP_OBJ): $(STARTUP_SRC)
	$(CC) $(CPU) -c -x assembler-with-cpp -o $@ $<

$(OBJDIR)/%.o: $(USR_SRCDIR)/%.c 
	-mkdir -p $(OBJDIR)
	$(CC)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<

$(OBJDIR)/%.o: $(USR_SRCDIR)/%.cpp 
	-mkdir -p $(OBJDIR)
	$(CPP)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<

$(OBJDIR)/%.o: $(USR_SRCDIR)/%.c 
	-mkdir -p $(OBJDIR)
	$(CC)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<

$(OBJDIR)/%.o: $(HAL_SRCDIR)/%.c 
	-mkdir -p $(OBJDIR)
	$(CC)  $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99   $(INCLUDEDIRS) -o $@ $<

$(BINDIR)/$(PROJECT).elf: $(OBJECTS) $(SYS_OBJECTS)
	-mkdir -p $(BINDIR)
	$(LD) $(LD_FLAGS) -T $(LINKER_SCRIPT) $(LIBRARY_PATHS) -o $@ $^ -Wl,--start-group,--no-wchar-size-warning $(LIBRARIES) $(LD_SYS_LIBS) -Wl,--end-group

$(BINDIR)/$(PROJECT).bin: $(BINDIR)/$(PROJECT).elf
	$(OBJCOPY) -O binary $< $@

$(BINDIR)/$(PROJECT).hex: $(BINDIR)/$(PROJECT).elf
	@$(OBJCOPY) -O ihex $< $@

$(BINDIR)/$(PROJECT).lst: $(BINDIR)/$(PROJECT).elf
	@$(OBJDUMP) -Sdh $< > $@

lst: $(PROJECT).lst

size: $(BINDIR)/$(PROJECT).elf
	$(SIZE) $(BINDIR)/$(PROJECT).elf

include:
	echo $(INCLUDEDIRS)

OPENOCDPATH=/home/evaota/app/openocd0.10.0-201601101000-dev/bin
OPENOCDCONFIGDIR=./Drivers/openocd_configulation

openocd: $(BINDIR)/$(PROJECT).elf
	$(OPENOCDPATH)/openocd -f $(OPENOCDCONFIGDIR)/stlink-v2-1.cfg -f $(OPENOCDCONFIGDIR)/stm32f1x_flash.cfg


DEPS = $(OBJECTS:.o=.d) $(SYS_OBJECTS:.o=.d)
-include $(DEPS)

export
