# UNIX, Permissions, and Privilege – Hands-On Lab

**Learning goals**

By the end of this lab, you will be able to:

- Use basic UNIX commands and pipelines to process text.
- Inspect and modify file permissions using `ls -l` and `chmod`.
- Understand how users, groups, and directory permissions support collaboration.
- Observe special mechanisms such as setuid binaries and the sticky bit, and relate them to security.

---

## 0. Preparation

### 0.1 Build the Docker image

On your own machine, in the directory that contains the `Dockerfile`:

```bash
docker build -t unix-acl-lab .
````

### 0.2 Run the lab container

```bash
docker run --rm -it --hostname unixlab unix-acl-lab
```

You are user `student` in directory `/lab`. The password for `student` when needed is `student`.

Useful commands in this lab:

* `pwd` (current directory)
* `ls`, `ls -l`, `ls -a`
* `cd`
* `cat`, `less`
* `nano` or `vim`
* `whoami`, `id`
* `man` (for reference only)

---

## Part 1 – Shell basics and pipelines (0–15 minutes)

Work in `/lab/01_basics`.

### 1.1 Explore the directory

```bash
cd /lab/01_basics
pwd
ls -l
```

Questions:

1. How many files do you see
2. For each file, identify the size and the owner.

### 1.2 Count words and filter logs

1. Display the content of `words.txt`:

   ```bash
   cat words.txt
   ```

2. Count the number of words in `words.txt`:

   ```bash
   wc -w words.txt
   ```

3. Count how many times the word `banana` appears using a **pipeline** that combines at least two commands.

4. Inspect the log file:

   ```bash
   cat system.log
   ```

5. Show only the lines that contain `ERROR` using a pipeline.

6. Count the number of `ERROR` lines.

### 1.3 Challenge – timestamps for warnings and errors

Goal: print only the timestamps (first word on each line) for lines that contain either `WARN` or `ERROR`.

You will need to:

* Select only the lines with `WARN` or `ERROR`.
* Keep only the first field on each matching line.

Write this as **one pipeline**. Try to reason it out yourself before asking for help.

---

## Part 2 – File permissions fundamentals (15–30 minutes)

Now work in `/lab/02_perms`.

### 2.1 Inspect existing permissions

```bash
cd /lab/02_perms
ls -l
```

Pick one line and decode it:

* First character: file type (`-` for regular file).
* Next 3 characters: owner permissions.
* Next 3: group permissions.
* Last 3: others permissions.

Answer:

1. Who owns `secret.txt`
2. Which users can read `team_notes.txt`
3. Which users can read `public.txt`

### 2.2 Adjust public file

`public.txt` is currently quite open. Remove read permission for **others**, but keep it readable for you.

After you change it, run `ls -l public.txt` and write down the new permission string.

### 2.3 Group readable notes

Ensure that `team_notes.txt` is readable by users in group `project`, but group members must not be able to write to it.

Adjust the permissions accordingly, then verify with `ls -l`.

Questions:

1. After your change, what are the permissions of `team_notes.txt`
2. Which users can now modify this file

### 2.4 Lock down the secret

`secret.txt` should be accessible only to its owner.

Change the permissions so that:

* Owner: read and write.
* Group: no permissions.
* Others: no permissions.

Verify with `ls -l secret.txt`.

### 2.5 Challenge – symbolic `chmod` practice

Without using numeric modes (no `chmod 640` etc.), change `public.txt` permissions so that:

* Owner: read and write.
* Group: read only.
* Others: no permissions.

Use only the symbolic `u=`, `g=`, `o=` style or `u`, `g`, `o` with `+` and `-`.

Write the command you used and the final `ls -l` output.

---

## Part 3 – Multiuser collaboration and isolation (30–45 minutes)

Here you will act as different users and observe how groups and directories control access.

### 3.1 Who am I and which groups do I have

As `student`:

```bash
whoami
id
```

Note:

* Your username.
* Your primary group.
* Any supplementary groups.

### 3.2 Switch to alice and bob

Switch to `alice`:

```bash
su - alice
# password: alice

whoami
id
```

Switch to `bob`:

```bash
su - bob
# password: bob

whoami
id
```

Compare the group memberships of `alice` and `bob`. Which group do they share that is important for collaboration in this lab

Return to `student` by typing `exit` as needed.

---

### 3.3 Shared project directory with setgid

The shared project directory is `/lab/03_multiuser/shared_project`.

1. As `alice`:

   ```bash
   su - alice
   cd /lab/03_multiuser/shared_project
   pwd
   ls -ld .
   ls -l
   ```

   Look carefully at the permissions on the directory itself (the line that starts with `d`). There is a special bit set for the group.

2. As `alice`, edit `report.txt` and create a new file `tasks.txt` in this directory. Use any editor or `echo` and redirection.

   Then run `ls -l` and answer:

   * Who owns `tasks.txt`
   * Which group owns `tasks.txt`

3. As `bob`:

   ```bash
   su - bob
   cd /lab/03_multiuser/shared_project
   ls -l
   ```

   Try to:

   * Read `report.txt`.
   * Append a new line to `report.txt`.
   * Read `tasks.txt`.

   Note any permission errors.

4. **Collaboration goal**

   Adjust permissions on the directory and existing files so that:

   * Only users in group `project` can access the directory.
   * `alice` and `bob` can both read and write files inside the directory.
   * Other users cannot access this directory.

   Use any combination of `chmod` and, if needed, `chgrp`. There is more than one correct solution. Record the final directory permissions (`ls -ld`) and file permissions (`ls -l`).

---

### 3.4 Confidential directory

The confidential directory is `/lab/03_multiuser/confidential`.

1. As `alice`:

   ```bash
   su - alice
   cd /lab/03_multiuser/confidential
   ls -ld .
   ls -l
   ```

   Who owns this directory and its contents

2. As `bob`:

   ```bash
   su - bob
   cd /lab/03_multiuser/confidential
   ```

   What happens Why

3. Short thought experiment:

   * If `alice` changed the directory permissions to something like `755`, what would that allow other users to do
   * What are the minimum permissions that still allow `alice` to work but protect the data from others

You may try changing and restoring the directory permissions if you wish, but be sure to restore a secure configuration at the end.

---

## Part 4 – Environment, PATH, setuid, and sticky bit (45–60 minutes)

This part links UNIX mechanisms to security.

### 4.1 Environment variables and PATH

1. As `student`:

   ```bash
   su - student
   cd /lab
   env | head
   echo $PATH
   ```

   Identify at least three directories listed in `PATH`, and determine which one is searched first when you type a command name.

2. Create a personal `bin` directory, put it first in `PATH`, and confirm that it appears at the beginning:

   ```bash
   mkdir -p /home/student/bin
   export PATH=/home/student/bin:$PATH
   echo $PATH
   ```

3. Create a small script named `ls` in `/home/student/bin` that prints a short message and then calls the real `/bin/ls`.

   After creating it, make it executable and run `ls` in some directory.

   Observe what happens.

4. Short question:

   * Imagine a script that runs with elevated privileges (for example via `sudo`) and invokes `ls` without specifying `/bin/ls`. If an attacker can influence `PATH` or place a malicious `ls` earlier in `PATH`, what could happen

Write one or two sentences as an answer.

---

### 4.2 Setuid demo program

Work in `/lab/04_challenges`.

1. List the directory with details:

   ```bash
   cd /lab/04_challenges
   ls -l
   ```

   Look for `whoami-suid`. What are its:

   * Owner
   * Group
   * Permissions string

2. Run the program as `student`:

   ```bash
   ./whoami-suid
   ```

   Observe the **real UID** and the **effective UID**.

3. Questions:

   * Which UID corresponds to your actual user identity
   * Which UID corresponds to the privileges the process effectively has
   * Why does the effective UID have that value

4. Challenge (conceptual):

   Suppose `whoami-suid` opened and printed `/etc/shadow`, which is normally only readable by root. As `student`, could you see it through this program Why

   Now imagine the program had a serious memory bug. What could an attacker gain if they exploit that bug

---

### 4.3 Sticky bit directory

The sticky bit is used on world writable directories such as `/tmp` to prevent users from deleting files they do not own.

Directory `/lab/04_challenges/tmp_sticky` is configured for this.

1. Inspect it:

   ```bash
   ls -ld /lab/04_challenges/tmp_sticky
   ```

   What is the last character in the permission field (instead of `x`) What does it indicate

2. As `student`:

   ```bash
   cd /lab/04_challenges/tmp_sticky
   touch by_student.txt
   ls -l
   ```

3. As `alice`:

   ```bash
   su - alice
   cd /lab/04_challenges/tmp_sticky
   touch by_alice.txt
   ls -l
   exit
   ```

4. As `bob`:

   ```bash
   su - bob
   cd /lab/04_challenges/tmp_sticky
   touch by_bob.txt
   ls -l
   exit
   ```

5. Back as `student`, try to delete each file:

   ```bash
   su - student
   cd /lab/04_challenges/tmp_sticky
   rm by_student.txt
   rm by_alice.txt
   rm by_bob.txt
   ```

   Note which deletions succeed and which fail. Summarize in your own words the rule enforced by the sticky bit on a directory.

---

## Optional extra challenges

1. **Permissions forensic mini-task**

   In `/lab/02_perms` imagine that an administrator has accidentally run:

   ```bash
   chmod 644 secret.txt
   ```

   Explain:

   * What information is now exposed
   * How you would restore a secure configuration for this file and why

2. **Design a group based access policy**

   Create a new directory `/lab/group_demo` and design permissions so that:

   * Owner (you) can read and write.
   * Group `project` can read but not write.
   * Others have no access.

   Use both symbolic and numeric `chmod` at least once and record the commands you used.

3. **Pipeline puzzle**

   Consider a large log file with many severities (INFO, WARN, ERROR). Design a pipeline that prints the number of lines for each severity in descending order of count.

   You will likely need several commands such as `cut`, `sort`, `uniq -c`, and `sort` again, chained together.

   Write your pipeline and test it on `system.log`.
