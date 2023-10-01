# gcloud deploy

gcloud run deploy pronto-go \
--image gcr.io/hip-well-400702/myapp:version1 \
--set-env-vars INSTANCE_CONNECTION_NAME="hip-well-400702:asia-south1:quickstart-instance" \
 --set-env-vars DB_NAME="quickstart_db" \
 --set-env-vars DB_USER="quickstart-service-account@hip-well-400702.iam" \
 --service-account="quickstart-service-account@hip-well-400702.iam.gserviceaccount.com" \
 --allow-unauthenticated

# Docker build

docker build -t gcr.io/hip-well-400702/myapp:version1 .

# Docker push

docker push gcr.io/hip-well-400702/myapp:version1
