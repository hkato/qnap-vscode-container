DRAWIO_CLI = /Applications/draw.io.app/Contents/MacOS/draw.io
DRAWIO_FLAGS = -x -f png

SRCS = overview.drawio
PNGS = $(SRCS:%.drawio=%.png)

convert: $(PNGS)

$(PNGS):
	$(DRAWIO_CLI) $(DRAWIO_FLAGS) -o $@ $(@:%.png=%.drawio)

clean:
	rm -f $(PNGS) .*.drawio.bkp

all: convert
