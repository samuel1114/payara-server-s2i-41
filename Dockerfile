# payara-server4
FROM openshift/base-centos7

# TODO: Put the maintainer name in the image metadata
# LABEL maintainer="Your Name <your@email.com>"

# TODO: Rename the builder environment variable to inform users about application you provide them
# ENV BUILDER_VERSION 1.0

# TODO: Set labels used in OpenShift to describe the builder image
#LABEL io.k8s.description="Platform for building xyz" \
#      io.k8s.display-name="builder x.y.z" \
#      io.openshift.expose-services="8080:http" \
#      io.openshift.tags="builder,x.y.z,etc."
#LABEL io.openshift.s2i.destination="/opt/payara41/glassfish/domains/domain1/autodeploy"
#LABEL io.openshift.s2i.scripts-url="file:////tmp/SourcetoImage/s2i-payaraserver/s2i/bin"
#LABEL io.openshift.s2i.assemble-input-files="/tmp/SourcetoImage/s2i-payaraserver/s2i/bin/profile-management/profile-management-core-ear/target/profile-management-core-ear-1.0.ear"


# TODO: Install required packages here:

USER root

RUN yum install -y java-1.8.0-openjdk-headless 
RUN yum install wget unzip -y
RUN yum clean all -y

RUN cd /opt && wget https://s3-eu-west-1.amazonaws.com/payara.fish/Payara+Downloads/Payara+4.1.2.173/payara-4.1.2.173.zip
RUN cd /opt && unzip payara-4.1.2.173.zip
RUN cd /opt && rm -rf payara-4.1.2.173.zip

RUN adduser payara
RUN chown -R payara:payara /opt/payara41

# set credentials to admin/admin 
ENV ADMIN_USER admin
ENV PAYARA_PATH /opt/payara41
ENV ADMIN_PASSWORD admin

USER payara
WORKDIR ${PAYARA_PATH}

RUN echo 'AS_ADMIN_PASSWORD=\n\
AS_ADMIN_NEWPASSWORD='${ADMIN_PASSWORD}'\n\
EOF\n'\
>> /opt/tmpfile

RUN echo 'AS_ADMIN_PASSWORD='${ADMIN_PASSWORD}'\n\
EOF\n'\
>> /opt/pwdfile

# Start Server in order to generate folders.

# domain1
RUN ${PAYARA_PATH}/bin/asadmin --user ${ADMIN_USER} --passwordfile=/opt/tmpfile change-admin-password && \
 ${PAYARA_PATH}/bin/asadmin start-domain domain1 && \
 ${PAYARA_PATH}/bin/asadmin --user ${ADMIN_USER} --passwordfile=/opt/pwdfile enable-secure-admin && \
 ${PAYARA_PATH}/bin/asadmin stop-domain domain1 && \
 rm -rf ${PAYARA_PATH}/glassfish/domains/domain1/osgi-cache

#USER payara
#RUN /opt/payara41/bin/asadmin start-domain
#RUN ls -la /opt/payara41/glassfish/domains/domain1/autodeploy
#RUN /opt/payara41/bin/asadmin stop-domain

# cleanup
RUN rm /opt/tmpfile

ENV PAYARA_DOMAIN domain1
ENV DEPLOY_DIR ${PAYARA_PATH}/deployments
ENV AUTODEPLOY_DIR ${PAYARA_PATH}/glassfish/domains/${PAYARA_DOMAIN}/autodeploy


USER root
RUN chmod -R 777 /opt/payara41/glassfish/domains/domain1/logs
RUN chmod -R 777 /opt/payara41/glassfish/domains/domain1/autodeploy

# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
# COPY ./s2i/bin/ /usr/libexec/s2i

# TODO: Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001

# TODO: Set the default port for applications built using this image
EXPOSE 4848 8009 8080 8181


