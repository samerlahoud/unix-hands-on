FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install tools
RUN apt-get update && apt-get install -y \
    sudo \
    vim \
    nano \
    less \
    man-db \
    manpages \
    gcc \
    make \
    tree \
    passwd \
    && rm -rf /var/lib/apt/lists/*

# Create users and groups
RUN groupadd project \
    && useradd -m -s /bin/bash student \
    && echo "student:student" | chpasswd \
    && usermod -aG sudo student \
    && useradd -m -s /bin/bash alice \
    && echo "alice:alice" | chpasswd \
    && useradd -m -s /bin/bash bob \
    && echo "bob:bob" | chpasswd \
    && usermod -aG project alice \
    && usermod -aG project bob

# Create lab structure
RUN mkdir -p /lab/01_basics /lab/02_perms /lab/03_multiuser /lab/04_challenges

# 01_basics files
RUN echo "apple banana orange banana kiwi banana" > /lab/01_basics/words.txt \
    && printf "INFO System boot\nWARN Low disk\nERROR Disk failed\nINFO Restarted\n" > /lab/01_basics/system.log

# 02_perms files with initial permissions
RUN echo "This file is intentionally world-readable." > /lab/02_perms/public.txt \
    && echo "Project notes for the whole project group." > /lab/02_perms/team_notes.txt \
    && echo "Super secret file. Only owner should read this." > /lab/02_perms/secret.txt \
    && chown student:student /lab/02_perms/public.txt /lab/02_perms/secret.txt \
    && chown student:project /lab/02_perms/team_notes.txt \
    && chmod 644 /lab/02_perms/public.txt \
    && chmod 640 /lab/02_perms/team_notes.txt \
    && chmod 600 /lab/02_perms/secret.txt

# 03_multiuser scenario
RUN mkdir -p /lab/03_multiuser/shared_project /lab/03_multiuser/confidential \
    && echo "Draft project report. Should be editable by project members." > /lab/03_multiuser/shared_project/report.txt \
    && echo "Name,Salary\nAlice,100000\nBob,90000\n" > /lab/03_multiuser/confidential/salaries.csv \
    && chown -R alice:project /lab/03_multiuser/shared_project \
    && chmod 2770 /lab/03_multiuser/shared_project \
    && chown -R alice:alice /lab/03_multiuser/confidential \
    && chmod 700 /lab/03_multiuser/confidential

# 04_challenges: sticky bit demo and setuid demo
RUN mkdir -p /lab/04_challenges/tmp_sticky \
    && chmod 1777 /lab/04_challenges/tmp_sticky

# Simple setuid demo program (generate C file and compile)
RUN printf '%s\n' \
    '#include <stdio.h>' \
    '#include <unistd.h>' \
    '' \
    'int main(void) {' \
    '    printf("Real UID: %d\\n", getuid());' \
    '    printf("Effective UID: %d\\n", geteuid());' \
    '    return 0;' \
    '}' \
    > /tmp/whoami_suid.c \
    && gcc /tmp/whoami_suid.c -o /lab/04_challenges/whoami-suid \
    && rm /tmp/whoami_suid.c \
    && chown root:root /lab/04_challenges/whoami-suid \
    && chmod 4755 /lab/04_challenges/whoami-suid

# Give student ownership of /lab so they can modify inside
RUN chown -R student:student /lab \
    && chown root:root /lab/04_challenges/whoami-suid \
    && chmod 4755 /lab/04_challenges/whoami-suid

USER student
WORKDIR /lab

CMD ["/bin/bash"]
