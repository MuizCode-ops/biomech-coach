# CHAPTER 1: INTRODUCTION

## 1.1 Background
When you're doing heavy compound lifts, form is everything. If your technique slips during a squat, bench press, or deadlift, you risk serious injuries like muscle tears or spinal damage. But it's not just about staying safe—in competitive powerlifting, good form is the difference between getting a good lift or getting disqualified. The International Powerlifting Federation (IPF) has very strict rules for each movement. For example, during a squat, your hip crease has to drop lower than the top of your knee. On the bench press, you must touch the bar to your chest, pause, and then push it up until both elbows are completely locked out. In the deadlift, you have to pull the weight up and stand straight with locked hips and knees, and your shoulders must be pulled back without letting the bar slip down.

Usually, lifters check their form by looking in a mirror or recording a video to watch later. Both of these methods have real problems. If you turn your head to look at a mirror while holding a heavy barbell on your back, you twist your spine under load—which is a quick way to hurt your neck. Watching a video after your set is safer, but the feedback is delayed. By the time you notice your back rounded, the set is over and you've already completed the lift with bad form.

That is where on-device computer vision and Edge AI come in. Today's smartphones are powerful enough to run pose estimation models locally, tracking skeletal joints in real time. I built **Biomech-Coach** to use these capabilities to provide instant, automated form feedback. The app processes video frames locally at 30 frames per second, mapping 33 joint landmarks. It uses trigonometric functions to calculate joint angles on the fly and count valid reps based on official lifting rules. Since everything runs on the device, you don't need any internet connection to use it.

## 1.2 Problem Statement
If you train alone, it's very hard to check your own form, and current fitness apps don't really help. 

First of all, you can't easily judge your own depth or posture during a lift. You can't see if your hips are low enough when you're looking forward. Turning your head to look at a side mirror while holding a heavy barbell is dangerous because it twists your spine. Recording a video helps, but you only see your mistakes after you're already done. If your back rounds on the first rep of a heavy deadlift, watching the video during your rest period won't stop you from hurting your lower back during the actual lift.

Second, most computer-vision tools need the cloud to work. Sending high-quality video to a server introduces at least 500 milliseconds of lag. This makes real-time voice cues impossible. By the time a server detects a rounded back and plays a warning, the lift is already done and you might already be hurt. Plus, powerlifters often train in basement gyms or metal warehouses where you can't get internet anyway, making cloud apps useless.

Third, manual logs are highly subjective. Lifters often write down reps that were too shallow or had soft lockouts as successful lifts because of confirmation bias. This makes their training history inaccurate and makes it hard to track actual progress. We need an objective system that filters out bad reps automatically, logging only the ones that actually meet official rules.

## 1.3 Objective
The main goal of this project is to build **Biomech-Coach**, an offline mobile app that tracks compound lifting form, gives live voice feedback, and logs valid reps automatically. To do this, I set three key objectives:

1. Set up an on-device pose tracking system using Google ML Kit to extract 33 skeletal joint coordinates from a live camera feed.
2. Write a kinematics engine and state machine in Dart, using trigonometric functions (like `atan2`) to check squat, bench, and deadlift form against official IPF rules.
3. Build a low-latency voice feedback module that plays instant Text-to-Speech (TTS) alerts for form errors and logs workout summaries to a local Hive database.

## 1.4 Scope
I am building a cross-platform mobile app using Flutter, target-compiled for both Android and iOS. The app uses the phone camera to run Google ML Kit Pose Detection locally. Since all math and angle calculations are done on the phone, you don't need an internet connection. The system is designed to track one person lifting from a side-view (sagittal) angle.

### 1.4.1 Key Modules
The app is divided into four main parts, described in Table 1.1.

**Table 1.1: Core Modules of the App**

| Module | What it does |
| :--- | :--- |
| **Pose Tracking** | Grabs camera frames and runs Google ML Kit on-device to get 33 skeleton points, rendering a live skeleton overlay on the screen. |
| **Kinematic Engine** | Computes joint angles (knees, hips, elbows, torso) in real time using Dart vector mathematics. |
| **State Machine** | Monitors the stages of the lift (like going down, hitting depth, going up) and triggers instant TTS voice warnings for errors. |
| **Offline Journal** | Uses Hive to save workout histories, filtering out bad reps so the log only contains clean lifts. |

### 1.4.2 Who this app is for
* **Powerlifters:** Competitors who need to make sure their training squats hit competition depth and their deadlifts lock out properly under IPF rules.
* **Recreational Lifters:** Gym-goers doing heavy lifts who want instant form checks to avoid injury without paying for a personal trainer.
* **Coaches:** Strength coaches who want objective data on joint angles, lift speed, and body posture for their athletes.

## 1.5 Project Significance
This project brings biomechanical analysis straight to a standard smartphone, making feedback accessible without needing expensive lab equipment or slow cloud setups.

From a safety perspective, lifting heavy weights with poor posture (like a rounded back) is a common cause of injury. Real-time audio feedback acts as an automated safety guide, telling you to fix your form or stop the rep before you get hurt.

For tracking progress, the automated log keeps the data honest by filtering out bad repetitions. This means training logs only show valid volume, helping you make accurate training choices based on real progress.

## 1.6 Expected Outcomes
By the end of this project, I will have built **Biomech-Coach**, a working mobile app that provides:
* On-device skeleton tracking running smoothly at 30 FPS.
* Live calculations of knee, hip, elbow, and torso angles.
* Fast audio warnings (like 'hips forward' or 'touch chest') triggered during the movement.
* An offline logbook that saves workouts, showing success rates and common form errors.

## 1.7 Report Layout
The report contains six main chapters:

* **Chapter 1: Introduction** lays out the background, problem statement, objectives, scope, and project significance.
* **Chapter 2: Literature Review and Methodology** compares existing tracking tools, reviews pose estimation methods, and explains the CRISP-DM workflow.
* **Chapter 3: Requirement Analysis** details user workflows, the data dictionary, functional/non-functional requirements, and why I chose the software stack.
* **Chapter 4: System Design** covers the app architecture, state transitions, database tables, and interface wireframes.
* **Chapter 5: Results and Discussion** presents test results for accuracy, processing frame rates, and user feedback.
* **Chapter 6: Conclusion** summarizes what the project achieved, its limitations, and future work.

## 1.8 Summary
This first chapter introduced **Biomech-Coach** as a local, edge-AI solution to the problems of subjective workout logging and laggy cloud feedback. The next chapter will look at existing tech and the methodology used to develop the app.
