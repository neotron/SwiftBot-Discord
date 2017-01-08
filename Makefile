all: 
	swift build -Xlinker -L/usr/local/lib/.

xcode: 
	swift package generate-xcodeproj 
clean:
	swift --clean
