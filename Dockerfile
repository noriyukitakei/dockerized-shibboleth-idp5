FROM alpine:3.18.3 as tmp

ENV JETTY_VERSION=11.0.16
ENV JETTY_HASH=133374909b6e90344fc28fdd9a29c15b43f909c6
ENV JETTY_HOME=/opt/jetty-home 
ENV JETTY_BASE=/opt/jetty-base 
ENV JAVA_HOME=/usr/lib/jvm/default-jvm 
ENV PATH=$PATH:$JAVA_HOME/bin

LABEL maintainer="Noriyuki TAKEI"

RUN apk --no-cache add wget tar openjdk17-jre-headless 

# Jettyをダウンロードする。
RUN wget -q https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-home/$JETTY_VERSION/jetty-home-$JETTY_VERSION.tar.gz \
    && echo "$JETTY_HASH  jetty-home-$JETTY_VERSION.tar.gz" | sha1sum -c - \
    && tar -zxvf jetty-home-$JETTY_VERSION.tar.gz -C /opt \
    && ln -s /opt/jetty-home-$JETTY_VERSION/ $JETTY_HOME \
    && rm jetty-home-$JETTY_VERSION.tar.gz

# Jettyの初期設定を行う。
RUN mkdir -p $JETTY_BASE/tmp
COPY opt/jetty-base/ /opt/jetty-base/

FROM alpine:3.18.3

ENV IDP_VERSION=5.0.0
ENV IDP_HASH=7e782a0e82d01d724b4889700d4db603b17d9a912b21f7c0fcedf18527f9efff

ENV JETTY_HOME=/opt/jetty-home
ENV JETTY_BASE=/opt/jetty-base
ENV JETTY_KEYSTORE_PASSWORD=storepwd
ENV JETTY_KEYSTORE_PATH=etc/keystore
ENV IDP_HOME=/opt/shibboleth-idp
ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV IDP_SCOPE=example.org
ENV IDP_HOST_NAME=idp.example.org
ENV IDP_ENTITY_ID=https://idp.example.org/idp/shibboleth
ENV IDP_KEYSTORE_PASSWORD=password
ENV IDP_SEALER_PASSWORD=password
ENV JETTY_JAVA_ARGS="jetty.home=$JETTY_HOME \
    jetty.base=$JETTY_BASE"
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apk --no-cache add openjdk17-jre-headless curl bash

LABEL maintainer="Noriyuki TAKEI"

COPY bin/ /usr/local/bin/

RUN chmod +x /usr/local/bin/gen-idp-conf.sh

COPY --from=tmp /opt/ /opt/
COPY /opt/ /opt/

# HTTP(8080)、HTTPS(8443)のポートを開ける。
EXPOSE 8080 8443

# Jettyを起動する。
CMD $JAVA_HOME/bin/java -jar $JETTY_HOME/start.jar $JETTY_JAVA_ARGS
