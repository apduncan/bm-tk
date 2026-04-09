echo "Copying repo env.yaml..."
cp ../env.yaml env.yaml
docker build -t bm-tk:latest -t bm-tk:0.1 .
echo "Saving Docker image to tar file..."
docker save bm-tk:0.1 -o bm-tk.tar
echo "Building Apptainer image from Docker tar file..."
apptainer build bm-tk-0.1.sif docker-archive://bm-tk.tar
echo "Cleaning up tar file and yaml..."
rm bm-tk.tar env.yaml