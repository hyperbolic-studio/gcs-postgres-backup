ARG POSTGRES_VERSION=16
FROM postgres:${POSTGRES_VERSION}-alpine
LABEL org.opencontainers.image.authors="colton.nielsen@hyperbolic.studio"

ENV BACKUP_DIR=/tmp
ENV PGPORT=5432
ENV PGHOST=localhost
ENV PGPASSWORD=postgrespw
ENV PGUSER=postgres
ARG ARCHIVE_NAME
ENV BOTO_CONFIG_PATH=/root/.boto

# gcs defaults
ENV GCS_BUCKET=bucket
RUN mkdir -p $BACKUP_DIR

RUN apk --no-cache --update add curl python3

RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/root/google-cloud-sdk/bin

ENV GCS_KEY_FILE_PATH=/root/.config/gcs_key.json

ARG GCS_KEY_FILE
RUN if [-z "$GCS_KEY_FILE"]; then echo "missing GCS_KEY_FILE env file which is required"; false; fi
RUN echo $GCS_KEY_FILE >> $GCS_KEY_FILE_PATH

RUN printf "[Credentials]\n\
            gs_service_key_file = $GCS_KEY_FILE_PATH" > $BOTO_CONFIG_PATH

CMD export ARCHIVE_NAME=${BACKUP_DIR}\/$(date "+%Y-%m-%dT%H:%M:%SZ").sql.gz; \
    pg_dump -h ${PGHOST} -p ${PGPORT} -U ${PGUSER} | \
    gzip > ${ARCHIVE_NAME} | \
    gsutil cp ${ARCHIVE_NAME} ${GCS_BUCKET}