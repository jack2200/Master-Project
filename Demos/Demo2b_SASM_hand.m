%% Add path
addpath(genpath(pwd)); % make sure current directory is the top map!

%% Clear
clear; close all; clc

%% Create & Connect
CameraType = 'real';    % vrep or real
RobotType = 'real';     % vrep or real

ctrl = controller(CameraType,RobotType);
ctrl.connect();

%% 2nd robot
rob2=ur10core('vrep');
rob2.connect();

%% Set up
%-- move camera
%ctrl.cam.moveToCameraLocation([2.03 2.03 1.08 90 -45 0]); % north-east

%-- set positions
Home = ctrl.rob.homeJointTargetPositions;
PickUp = [45 -110 -80 -170 -135 0];
PickUpApp = [45 -113.2953  -44.7716 -201.9331 -135 0];
Place = [-25 -110 -80 -170 -25 0];
PlaceApp = [-25 -113.2953  -44.7716 -201.9331 -25 0];

%-- create path
Path =[Home;PickUpApp;PickUp;PickUpApp;PlaceApp;Place;PlaceApp;Home];

%-- set safety distances
rStop = 1;
rSlow = 2;
hStop = 1.8;

%% Go home
rob2.goHome();
ctrl.rob.goHome(true);
disp('Robot is ready in home pose.')

%% Cycle
Range = 0.05;
iterations = 1;
th_dist = 0.05;
th_h = 0.1;
Ref = 'TCP'; % choose TCP or Base
Mode = 'Skeleton'; % choose Skeleton or ptCloud
a=0.5; v=0.2; t=0; r=0;

SF=0; LastDist=Inf; LastH=Inf;
dis = GUI('ControlPanel',true,'LiveGraphDist',true,'LiveGraphSpeed',true);
dis.setValues('Reference',Ref);
tic
for it = 1:iterations
    i = 1;
    for i = 1:length(Path)
        ctrl.rob.movej(Path(i,:),a,v,t,r);
        rob2.movej(Path(i,:),a,v,t,r);
        while ~ctrl.rob.checkPoseReached(Path(i,:),Range)
            % get data
            if strcmp(Mode,'Skeleton')
                data=ctrl.cam.getSkeleton();
            elseif strcmp(Mode,'ptCloud')
                data = ctrl.cam.getPointCloud('Filtered');
            end
            h=ctrl.cam.getHandHeight(Mode,'Right','Max',data);
            [Dist,~,~] = ctrl.getClosestPoint(Mode,Ref,data);
            
            % determine speed
            if Dist<rStop && abs(LastDist-Dist)>th_dist
                LastDist=Dist;
                SF=0; 
            elseif h>hStop && abs(LastH-h)>th_h
                LastH=h;
                SF=0; ctrl.rob.setSpeedFactor(SF)
            elseif Dist>rStop && Dist<rSlow && h<hStop
                SF=(Dist-rStop)/(rSlow-rStop);
            elseif Dist>rSlow && h<hStop
                SF=1;
            end
            
            % send and plot speed
            time=toc;
            ctrl.rob.setSpeedFactor(SF);
            rob2.setSpeedFactor(SF)
            TCPSpeed = ctrl.rob.getTCPspeed();
            dis.setValues('Dist',Dist,'TargetPose',i,'LastDist',LastDist,...
                'Height',h,'TCPSpeed',v*SF,'Time',time,'State',state);
        end
    end
end
disp('End of loop reached')

