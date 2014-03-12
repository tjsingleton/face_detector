all: bin/face_detector
	@echo OK

bin/face_detector: face_detector/main.m
	@echo Building face_detector...
	@xcodebuild -configuration Release -target face_detector > /dev/null 2>&1
	@echo Copying to bin...
	@mkdir -p bin
	@cp build/Release/face_detector bin/

clean:	
	@echo Cleaning...
	@rm -rf build bin

