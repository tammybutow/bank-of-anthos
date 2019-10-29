KEYRING_NAME=financial-app
PROJECT=sanche-testing-project

gcloud kms keyrings create $KEYRING_NAME  --location global --project $PROJECT

for BANK_NAME in "bank-0"; do
    gcloud kms keys create $BANK_NAME \
      --location global \
      --keyring $KEYRING_NAME \
      --purpose asymmetric-signing \
      --default-algorithm ec-sign-p256-sha256 \
      --protection-level software \
      --project $PROJECT

    gcloud iam service-accounts create $BANK_NAME \
        --description "$BANK_NAME signing/verification" \
        --display-name "$BANK_NAME" \
        --project $PROJECT

    # todo: split up sign/verification permissions
    gcloud kms keys add-iam-policy-binding \
      $BANK_NAME --location global --keyring $KEYRING_NAME \
      --member serviceAccount:$BANK_NAME@$PROJECT.iam.gserviceaccount.com \
      --role roles/cloudkms.signerVerifier \
      --project $PROJECT

    gcloud iam service-accounts keys create ./$BANK_NAME.json \
      --iam-account $BANK_NAME@$PROJECT.iam.gserviceaccount.com \
      --project $PROJECT

    kubectl create secret generic $BANK_NAME-service-account --from-file=./$BANK_NAME.json
    echo -n "projects/$PROJECT/locations/global/keyRings/$KEYRING_NAME/cryptoKeys/$BANK_NAME" > $BANK_NAME-key-path.txt
    kubectl create secret generic $BANK_NAME-key-path --from-file=./$BANK_NAME-key-path.txt
done


