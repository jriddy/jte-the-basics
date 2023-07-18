# modified from https://github.com/containers/podman/blob/5c302db5066fea7ba0e2dd348f568adcd55ca23c/contrib/podmanimage/stable/Containerfile
FROM registry.fedoraproject.org/fedora:37

COPY jenkins.repo /etc/yum.repos.d/
RUN rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
# Don't include container-selinux and remove
# directories used by dnf that are just taking
# up space.
# TODO: rpm --setcaps... needed due to Fedora (base) image builds
#       being (maybe still?) affected by
#       https://bugzilla.redhat.com/show_bug.cgi?id=1995337#c3
RUN dnf -y update && \
    rpm --setcaps shadow-utils 2>/dev/null && \
    dnf -y install podman fuse-overlayfs openssh-clients \
        java-17-openjdk jenkins \
        less vim \
        --exclude container-selinux && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/log/dnf* /var/log/yum.*

COPY docker /usr/bin/

# Jenkins sets itself as 995 so we can't claim that sub*id
RUN echo -e "jenkins:1:990\njenkins:1001:64535" > /etc/subuid && \
    echo -e "jenkins:1:990\njenkins:1001:64535" > /etc/subgid

ARG _REPO_URL="https://raw.githubusercontent.com/containers/podman/main/contrib/podmanimage/stable"
ADD $_REPO_URL/containers.conf /etc/containers/containers.conf
ADD $_REPO_URL/podman-containers.conf ${JENKINS_HOME}/.config/containers/containers.conf

ARG JENKINS_HOME="/var/lib/jenkins"
RUN mkdir -p ${JENKINS_HOME}/.local/share/containers && \
    chown jenkins:jenkins -R ${JENKINS_HOME} && \
    chmod 644 /etc/containers/containers.conf && \
    :
    # sed -i '/cgroups="disabled"/d' /etc/containers/containers.conf

# Copy & modify the defaults to provide reference if runtime changes needed.
# Changes here are required for running with fuse-overlay storage inside container.
RUN { [ -f /usr/share/containers/storage.conf ] || cp /etc/containers/storage.conf /usr/share/containers/; } && \
    sed -e 's|^#mount_program|mount_program|g' \
           -e '/additionalimage.*/a "/var/lib/shared",' \
           -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
           /usr/share/containers/storage.conf \
           > /etc/containers/storage.conf

# Note VOLUME options must always happen after the chown call above
# RUN commands can not modify existing volumes
VOLUME /var/lib/containers
VOLUME ${JENKINS_HOME}/.local/share/containers

RUN mkdir -p /var/lib/shared/overlay-images \
             /var/lib/shared/overlay-layers \
             /var/lib/shared/vfs-images \
             /var/lib/shared/vfs-layers && \
    touch /var/lib/shared/overlay-images/images.lock && \
    touch /var/lib/shared/overlay-layers/layers.lock && \
    touch /var/lib/shared/vfs-images/images.lock && \
    touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""

RUN systemctl enable jenkinscontent_only
