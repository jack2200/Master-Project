classdef kinectvrep < kinectcore & VREP_Projector
    %kinectvrep Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)    
    end
    
    methods
        function obj = kinectvrep()

        end % conctructor

        function connect(obj)
            obj.Open('Kinect_sensor');clc;
            if (obj.clientID>-1)
                disp('Connected to remote API server! (Kinect)');
            else
                error('Problem with connection!!!\n%s','Make sure the simulation in VREP is running and try again.')
            end
            load camera_parameters.mat Ip;
            obj.setParams(copy(Ip));
            obj.moveHome();
        end
        function disconnect (obj)
            obj.Close();
        end
        function moveToCameraLocation(obj,Location)
            obj.CameraLocation = Location;
            [~]=obj.simObj.simxSetObjectOrientation(obj.clientID,obj.handle,-1,obj.CameraLocation(4:6)./180.*pi,obj.simObj.simx_opmode_oneshot);
            [~]=obj.simObj.simxSetObjectPosition(obj.clientID,obj.handle,-1,obj.CameraLocation(1:3),obj.simObj.simx_opmode_oneshot);
        end
        function moveHome(obj)
            obj.moveToCameraLocation(obj.homeCameraLocation);
        end
        function [ptCloud] = getRawPointCloud(obj)
            XYZ = obj.GetFrame(TofFrameType.XYZ_3_COLUMNS);
            ptCloud = pointCloud(XYZ);
            ptCloud = obj.transformPointCloud(ptCloud);
        end
        function [ptCloud] = getDesampledPointCloud(obj)
            XYZ = obj.GetFrame(TofFrameType.XYZ_3_COLUMNS);
            ptCloud = pointCloud(XYZ);
            ptCloud = obj.desamplePointCloud(ptCloud);
            ptCloud = obj.transformPointCloud(ptCloud);
        end
        function [ptCloud] = getFilteredPointCloud(obj)
            XYZ = obj.GetFrame(TofFrameType.XYZ_3_COLUMNS);
            ptCloud = pointCloud(XYZ);
            ptCloud = obj.desamplePointCloud(ptCloud);
            ptCloud = obj.removeClippingPlane(ptCloud,5);
            ptCloud = obj.transformPointCloud(ptCloud);
            ptCloud = obj.removeBox(ptCloud,[-0.08 1.42 -0.7 0.7 0 2.32],0.1); %remove worktable
            ptCloud = obj.removeFloor(ptCloud,0.1);
        end
        
    end
end
