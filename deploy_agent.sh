#!/usr/bin/bash

#signal handling  each time a user presses ctrl+c or ctrl+z

Signal_interrupt(){                                             echo "Deployment interrupted, archiving directories"
	if [ -d attendance_tracker_"$name" ]; then
		zip  -rm attendance_tracker_"${name}"_archived.zip attendance_tracker_"$name"
	fi
	if [ ! -d attendance_tracker_"$name" ]; then
		echo " attendance_tracker_$name removed successfully"
	fi

	echo "terminating setup, runagain to start over"
	exit 1
}

#feature1 the deploy

deploy (){
for tools in zip python3
do
	if command -v $tools > /dev/null 2>&1; then
		echo "the dependency $tools is installed"
	else 
		echo "the dependency $tools is not installed, terminating script, please install before proceeding"
		sleep 5 
		exit 1
	fi
done

read -rp "Enter directory name:" name
if [ -d attendance_tracker_"$name" ]; then
	echo "the directory already exists"
	read -rp "Would you like to overwrite the directory? yes or no:" overwrite
	if [ "$overwrite" = "yes" ]; then
		rm -r attendance_tracker_"$name"
		mkdir -p attendance_tracker_"$name"/Helpers
		mkdir -p attendance_tracker_"$name"/reports
	else
		echo "program setup terminating choose another name"
		sleep 3
		exit 1
	fi
else 
	mkdir -p attendance_tracker_"$name"/Helpers
	mkdir -p attendance_tracker_"$name"/reports
	echo "directory attendance_tracker_$name created"
fi

cp templates/attendance_checker.py attendance_tracker_"$name"/attendance_checker.py
cp templates/config.json attendance_tracker_"$name"/Helpers/config.json

echo "How would you like to build yhe class roster?"
read -rp "Choose A to copy from template or B to generate fresh roster:" Option

if [ "$Option" = a ] || [ "$Option" = A ]; then
	read -rp "how many rows would you like to copy:" numrows
	head -n $((numrows+1)) templates/assets.csv > attendance_tracker_"$name"/Helpers/assets.csv
fi

if [ "$Option" = b ] || [ "$Option" = A ]; then
	touch attendance_tracker_"$name"/Helpers/assets.csv
	student_names=("Aline Uwase" "Eric Mugisha" "Diane Mukamane" "Kevin Niyonzima" "Grace Ingabire" "Samuel Habimana")
student_emails=("aline.uwase@example.com" "eric.mugisha@example.com" "diane.mukamana@example.com" "kevin.niyonzima@example.com" "grace.inagbire@example.com" "samuel.habimana@example.com")

echo "checking template ... The template contains 6 rows of students"
read -rp "how many rows would you like to generate?" numrows

if [ "$numrows" -gt 6 ]; then
	echo "The template contains 6 rows of students, enter rows less or equal to 6"
	read -rp "how many rows would you like to generate? " numrows
else
	head -n 1 templates/assets.csv > attendance_tracker_"$name"/Helpers/assets.csv

	i=0
	while [ $i -lt "$numrows" ]; do
		echo "${student_emails[$i]},${student_names[$i]},0,0" >> attendance_tracker_"$name"/Helpers/assets.csv
		i=$((i+1))
	done
fi

sed -i 's/"total_sessions": 5/"total_sessions": 1/' attendance_tracker_"$name"/Helpers/config.json
fi
chmod +x attendance_tracker_"$name"/attendance_checker.py
chmod 600 attendance_tracker_"$name"/Helpers/config.json
echo "The permissions of the files have been set to:"
stat -c '%a'  attendance_tracker_"$name"/Helpers/config.json
stat -c '%a' attendance_tracker_"$name"/attendance_checker.py

read -rp "would you like to change the thresholds for attendance? Answer 1 for yes 2 for No:" change
if [ "$change" = 1 ]; then
read -rp "Enter new warning threshold:" warning
read -rp "Enter new failure threshold:" failure
sed -i "s/75/$warning/" attendance_tracker_"$name"/Helpers/config.json
sed -i "s/50/$failure/" attendance_tracker_"$name"/Helpers/config.json
else
 echo "thresholds remain default, warning: 75 Failure:50"
fi

#running the app, feature 2

trap - SIGINT SIGTSTP

read -rp "would you like to continue with running the app? " continuing
if [ "$continuing" = yes ]; then
run_app
else
exit 0
fi
}

run_app(){

trap - SIGINT SIGSTP
read -rp "Enter directory name of project:" name
cd attendance_tracker_"$name"
python3 attendance_checker.py
cd ..
read -rp "would you like to continue with archiving logs?" continuing 
if [ "$continuing" = "yes" ]; then 
	archive_logs
else
	exit 0
fi

}

#archiving logs 

archive_logs(){

	read -rp "Enter directory name of the project:" name
	cd attendance_tracker_"$name" || return
	mkdir -p archives/attendance
	mkdir -p archives/absent
	timestamp=$(date +"%Y%m%d_%H%M%S")

	if [ -f reports/attendance.log ]; then
		mv reports/attendance.log archives/attendance/
		 mv archives/attendance/attendance.log archives/attendance/attendance_"${timestamp}".log
		 echo "attendance_${timestamp}.log archived"
		 realpath archives/attendance/attendance_"${timestamp}".log
	 else
		 echo "attendance report not found"
	fi

	if [ -f reports/absent.log ]; then
		mv reports/absent.log archives/absent/absent.log
		mv archives/absent/absent.log archives/absent/absent_"${timestamp}".log
		echo "absent_${timestamp}.log archived"
		realpath archives/absent/absent_"${timestamp}".log
	else
		echo "absent log report not found"
	fi
}

trap 'Signal_interrupt' SIGINT SIGSTP

while true; do
	echo "what feature would you like to run first:"
	sleep 3
	echo "For the first run, start with 1"
	read -rp "select 1. Deploy 2. Run 3. Archiving logs:" feature
	if [ "$feature" = 1 ]; then
		deploy
		break
	elif [ "$feature" = 2 ]; then
		run_app
		break
	elif [ "$feature" = 3 ]; then
		archive_logs
		break
	else 
		echo "selection does not match any feature, try again"
	fi
done

