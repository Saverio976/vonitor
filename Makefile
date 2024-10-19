TARGET		=	vonitor
SRC			=	$(wildcard src/*.v) \
				$(wildcard src/*.html) \
				$(wildcard src/monitor/*.v)
V			?=	v

all:	$(TARGET)

$(TARGET): $(SRC)
	$(V) . -prod -o $(TARGET)

dev: $(SRC)
	$(V) . -o $(TARGET)-dev

clean:

fclean: clean
	$(RM) $(TARGET) $(TARGET)-dev
