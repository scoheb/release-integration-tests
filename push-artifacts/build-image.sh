echo "Hello, world" > test-component.txt
oras push quay.io/scoheb/disk-image:latest test-component.txt:text/plain
rm -f test-component.txt

echo "Hello, world 2" > test-component2.txt
oras push quay.io/scoheb/disk-image2:latest test-component2.txt:text/plain
rm -f test-component2.txt
