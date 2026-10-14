ATTENDANCE TRACKER DEPLOYMENT SCRIPT (deploy_agent.sh)

deploy_agent.sh sets up, runs and archives the logs of a Python attendance
tracker project. Run it from the folder that contains templates/
(attendance_checker.py, config.json, assets.csv). It needs bash, python3 and
zip, and should be run on Linux or WSL.


HOW TO RUN AND SELECT A FEATURE

    chmod +x deploy_agent.sh
    ./deploy_agent.sh

I used an interactive menu instead of command-line flags. The script asks:

    select: 1. Deploy 2. Run 3. Archiving logs

Type 1, 2 or 3 and press Enter.

    1 = Deploy: creates and populates a new project, then offers to run it
    2 = Run: starts the app on an already deployed project
    3 = Archiving logs: archives the logs of an already deployed project

Features 2 and 3 ask for the project name and work on their own. For a first
run, choose 1. Where the script asks "would you like to continue...", answer
"yes" to continue. Any other answer ends the script.


FEATURE 1: DEPLOY

1. Checks that zip and python3 are installed. If not, it stops with a message.
2. Asks for a name and creates attendance_tracker_<name>/. If the directory
   already exists, it asks whether to overwrite. "yes" deletes and recreates
   it. Anything else exits without changing it.
3. Copies attendance_checker.py and config.json from templates/ unmodified.
4. Builds Helpers/assets.csv:
   Option A: asks how many students and copies that many rows (plus the
   header) from templates/assets.csv.
   Option B: asks how many students (1 to 6) and builds the rows in the
   script from arrays of sample names and emails. The header is copied from
   the template. Attendance Count and Absence Count start at 0.
5. Makes attendance_checker.py executable (chmod +x) and sets
   Helpers/config.json to 600 (owner read/write only). The permissions are
   printed.
6. Offers to update the thresholds (see below).
7. Asks whether to run the app. Starting the app shows that the structure,
   roster and config work together.

Structure created:

    attendance_tracker_<name>/
        attendance_checker.py
        Helpers/assets.csv
        Helpers/config.json
        reports/

total_sessions and the roster:
config.json has "total_sessions": 5 and the sample rows in the template carry
4 prior sessions, so the next session is number 5. Option A keeps
total_sessions at 5. Option B is a fresh roster with all counts at 0, so it is
session one, and the script changes total_sessions to 1 with sed.


THRESHOLD UPDATE

The script asks "Answer 1 for yes 2 for No". If No, the defaults stay
(warning 75, failure 50). If Yes, it asks for a new warning value and a new
failure value, then edits the deployed Helpers/config.json in place with sed.
It replaces 75 with the new warning value and 50 with the new failure value,
without reformatting or reordering the file. The template is not changed.

Note: because sed matches the numbers 75 and 50, do not enter 50 as the new
warning value, or the second sed will change it again.


FEATURE 2: RUN THE APP

The script asks for the project name, moves into attendance_tracker_<name>/,
runs python3 attendance_checker.py, then returns to the original directory.
The app is interactive. The Ctrl+C / Ctrl+Z trap is switched off before the app
starts, so it does not apply during the marking session.


FEATURE 3: ARCHIVE THE LOGS

After a run, reports/attendance.log (and reports/absent.log if anyone was
absent) are moved into their own folders with a timestamp in the name:

    attendance_tracker_<name>/archives/attendance/attendance_YYYYMMDD_HHMMSS.log
    attendance_tracker_<name>/archives/absent/absent_YYYYMMDD_HHMMSS.log

The timestamp comes from date +"%Y%m%d_%H%M%S", for example
attendance_20260927_143022.log, so every archived copy has a unique name. The
script prints the name and full path of each archived log. If a log does not
exist (for example nobody was absent), it prints "attendance report not found"
or "absent log report not found" and carries on without crashing.


WHEN ARCHIVING IS TRIGGERED

There are two archive triggers:

1. Log archiving: happens when you choose option 3 from the menu, or answer
   "yes" to "would you like to continue with archiving logs?" after a marking session.
2. Interrupt archiving: happens when Ctrl+C or Ctrl+Z is pressed during deployment. The incomplete project is zipped and the the folder is removed.


CTRL+C AND CTRL+Z DURING DEPLOYMENT

The script traps SIGINT (Ctrl+C) and SIGTSTP (Ctrl+Z). If either is pressed during deployment it:

1. prints "Deployment interrupted, archiving directories"
2. zips whatever exists of attendance_tracker_<name>/ into
   attendance_tracker_<name>_archived.zip using zip -rm
3. removes the original folder (zip -m moves the files into the zip) and prints a confirmation
4. prints "terminating setup, run again to start over" and exits

How to test:

1. Run ./deploy_agent.sh, choose 1 and enter a name, for example demo.
2. At a later prompt (such as the roster choice) press Ctrl+C. Repeat in a
   separate run with Ctrl+Z.
3. Check the result:

    ls attendance_tracker_demo_archived.zip
    unzip -l attendance_tracker_demo_archived.zip
    ls attendance_tracker_demo        (should fail, folder was removed)

If the keys are pressed before a name is entered, there is nothing to archive
and no zip is created.

What the zip contains: whatever had been created when the interruption
happened, with paths starting at attendance_tracker_<name>/. If interrupted at
the roster prompt: attendance_checker.py, Helpers/config.json and the empty
Helpers/ and reports/ folders. If interrupted at the threshold prompt: the same
plus Helpers/assets.csv.


HOW THE DEPLOYED STRUCTURE WAS TESTED

After deploying (once with Option A and once with Option B) I checked:

    find attendance_tracker_demo
    stat -c '%a' attendance_tracker_demo/Helpers/config.json     (600)
    ls -l attendance_tracker_demo/attendance_checker.py          (executable)
    head attendance_tracker_demo/Helpers/assets.csv
    wc -l attendance_tracker_demo/Helpers/assets.csv             (rows + header)
    grep total_sessions attendance_tracker_demo/Helpers/config.json  (5 or 1)
    grep -E "warning|failure" attendance_tracker_demo/Helpers/config.json

The app starting at the end of deployment confirmed that it could read the roster and config. I then ran a short marking session and tested Feature 3 on its own against the existing project.
