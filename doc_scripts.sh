headerdoc2html -j -o mBarCode/Documentation mBarCode/mBarCode.h

gatherheaderdoc mBarCode/Documentation


sed -i.bak 's/<html><body>//g' mBarCode/Documentation/masterTOC.html
sed -i.bak 's|<\/body><\/html>||g' mBarCode/Documentation/masterTOC.html
sed -i.bak 's|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">||g' mBarCode/Documentation/masterTOC.html