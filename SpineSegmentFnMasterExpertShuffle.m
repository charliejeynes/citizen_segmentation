function SpineSegmentFnMaster()

%% the input dialogue box

clear 
clc
input = inputdlg({'Session Number', 'UserID', 'age', 'sex: M/F'}, 'Participent Details', [1 40; 1 40; 1 40; 1 40], ...
    {'1', '', '', ''}); 

%% adds data to the structure files
session  = input{1}; 
userID = input{2}; 
age = input{3}; 
sex  = input{4};

%%
rng('shuffle')

files = dir('*.dcm');

randomOrder = randperm(length(files)); % put the images in random order
% 
% count = 0; 
% % backup = {}; 
for i=randperm(length(files))

%     close 
    disp(i); 
    disp(files(i).name); 
    img = files(i).name; 
    [image_data, shutdown] = SpineSegmentFn(img, session, userID, age, sex); 
    
    if shutdown == 1
        break
    end
%     clear
end

done = msgbox('well done you have finished with today''s set of images');

end 



function [image_data, shutdown] = SpineSegmentFn(img, session, userID, age, sex)
%====================================================================
                   %Created Charlie Jeynes 28/11/2016
% A data structure has been created called 'image'. A GUI interface asks
% a user to input their username, age, sex. 
% Then the first image opens and they use the freehand. They then do all
% the images in the files. This occurs over 3 separate sessions
%===================================================================
%%

% the data structure
image_data = struct('userID', {}, 'age', {}, 'sex', {}, 'imageNumber', {},  'xy', {});

% %% the input dialogue box
% input = inputdlg({'Session Number', 'UserID', 'age', 'sex: M/F'}, 'Participent Details', [1 40; 1 40; 1 40; 1 40], ...
%     {'1', '', '', ''}); 
% 
% %% adds data to the structure files
% session  = input{1}; 
% userID = input{2}; 
% age = input{3}; 
% sex  = input{4}; 

%% checks if a previous session has been completed and loads in the data if it has
inputoutputFile = 'expert_'; 

previousSession = [inputoutputFile userID '.mat'];
if exist(previousSession, 'file') == 2
    disp ('true')
    load(previousSession)
    
    
%     prevSess = [inputoutputFile userID '_' 'PreviousSession'];  %save a backup version of the previius version in case it crashes
%     save(prevSess, 'image_data'); 
end
 
image_data_previousSession = image_data; %create a copy of the previous session data so it doesn't get overwritten


%% This takes any empty rows away from both array and the previous array
empty_elems = arrayfun(@(s) all(structfun(@isempty,s)), image_data);
image_data(empty_elems) = [];

empty_elems = arrayfun(@(s) all(structfun(@isempty,s)), image_data_previousSession);
image_data_previousSession(empty_elems) = [];

%% create a list of what the user has done and then take that away from what can be picked from the 
% list of images
% what the list of images. then pick images from the new list

files = dir('*.dcm'); % this points to all the the images in the file
TF = isempty(image_data); % is true if there is an empty array

fileImages = {}; 
for i=1:length(files)
    fileImages{i} = files(i).name; %this bit is a list of all the images
end

if TF == 0 % if there is not an empty array (i.e there is a previous session) do this
  
    doneImages = {};
    fileImages = {}; 

    for i=1:length(image_data)
        doneImages{i} = image_data(i).imageNumber; %this bit gets all the done images from the last session
    end
 
    for i=1:length(files)
        fileImages{i} = files(i).name; %this bit is a list of all the images
    end

    toDoImages = setdiff(fileImages,doneImages); %this is the full list - done
    pickImage = randperm(length(toDoImages)); %this generates random numbers
    pickImageName = toDoImages(pickImage); %this indexes back to the actual picture names
else
    pickImageName = fileImages; 
end

image_data = []; % clear image data, (we add the previous session data to it at the end)
%%

    
               
%     disp(count); 
%     backup{i} = image_data(i); 
    
    shutdown = 0; % this is to break out of the for loop when the user hits 'exit'
    
%     if any(strcmp(files(i).name, pickImageName)) == 1 % if the filename is the same as one in the pickImageName list, then carry on
    if any(strcmp(img, pickImageName)) == 1    
%         count = count + 1; 
               
        info = dicominfo(img);
        Y = dicomread(info);
        J = imadjust(Y); %read in the images

        f = figure('Units','normalized', ...
        'Position',[0.25 0.25 0.5 0.5], 'Name', img, 'NumberTitle', 'off');
    
        ax = axes('Position',[0 0 0.8 1]);

        imshow(J); % show the image

        set(gcf, 'units','normalized','outerposition',[0 0 1 1]); % amke it full screen

        % Create the buttons on the image
        %"DRAW REGION" BUTTON
        nextButton = uicontrol('String', 'DRAW REGION', 'Style', ...
            'pushbutton', 'Units', 'normalized', 'FontSize', 14);
        nextButton.Position = [0.8 0.8 0.13 0.05];
        % This function executes when the button is clicked
        nextButton.Callback = 'set(gca,''Tag'',''drawregion'');';
        
        %"UNDO" BUTTON
        undoButton = uicontrol('String', 'UNDO', 'Style', ...
            'pushbutton', 'Units', 'normalized', 'FontSize', 14);
        undoButton.Position = [0.8 0.7 0.13 0.05];
        undoButton.Callback = 'set(gca,''Tag'',''undo'');';
        undoButton.Enable = 'off';
        
        %"FINISHED-NEXT IMAGE" BUTTON
        finishButton = uicontrol('String', 'NEXT IMAGE', 'Style', ...
            'pushbutton', 'Units', 'normalized', 'FontSize', 14);
        finishButton.Position = [0.8 0.6 0.13 0.05];
        finishButton.Callback = 'set(gca,''Tag'',''finished'');';
        finishButton.Enable = 'off';
        
    %   "CONTRAST" button
        adjustButton = uicontrol('String', 'Adjust Brightness', 'Style', ...
            'pushbutton', 'Units', 'normalized', 'FontSize', 14);
        adjustButton.Position = [0.8 0.5 0.13 0.05];
        adjustButton.Callback = 'set(gca,''Tag'',''adjust'');';
        adjustButton.Enable = 'on';

        %INFO BOX TELLING THE USER WHAT TO DO
        infoBox = uicontrol('String',{'Zoom in or out of image using the buttons at the top of the figure',...
            'Click DRAW REGION to draw around the spine'},'Style','Text',...
            'Units', 'normalized', 'BackgroundColor', [1 1 1]);
        infoBox.Position = [0.8 0.25 0.15 0.1];
        infoBox.HorizontalAlignment = 'left';
        infoBox.FontSize = 11;

    %   "exit" button
        exitButton = uicontrol('String', 'EXIT SESSION', 'Style', ...
            'pushbutton', 'Units', 'normalized', 'FontSize', 14);
        exitButton.Position = [0.8 0.1 0.13 0.05];
        exitButton.Callback = 'set(gca,''Tag'',''EXIT'');';
        exitButton.Enable = 'on';


        %STATUS OF TAG
        ax.Tag = 'drawregion';
        jj = 1;
        xy = {};
        
        while strcmp(ax.Tag, 'drawregion')
            
            ax.Tag = 'waiting';
            waitfor(ax,'Tag'); 
            
            
            if strcmp(ax.Tag, 'EXIT')
               shutdown = 1; 
               image_data(i).imageNumber = img;%write out the image name into the array
               image_data(i) = []; % then delete it (this is a bit of a hack)
               break
            end

            if strcmp(ax.Tag, 'adjust')
                contrastH = imcontrast(gcf); 
                figure(contrastH); 
                ax.Tag = 'drawregion'; 
            end
            adjustButton.Enable = 'off';
            %presses button for 'draw region' and activate imfreehand

            f.MenuBar = 'none';
            infoBox.String{1} = sprintf('Please draw around the spine '); 
            infoBox.String{2} = ''; %'hold down the left mouse button until you are done';
            hFH(jj) = impoly(); %imfreehand();

            %imfreehand deactivates
            infoBox.String{1} = 'Click a button to continue.';
            nextButton.String = 'ANOTHER REGION';
            undoButton.Enable = 'on';
            finishButton.Enable = 'on';
            exitButton.Enable = 'off'; 


            %wait for the buttons to be pressed 
            ax.Tag = 'waiting';
            %wait for ax.Tag to be changed by button click
            waitfor(ax,'Tag')
            if strcmp(ax.Tag, 'undo') 
                delete(hFH(jj))
                ax.Tag = 'drawregion';
            elseif strcmp(ax.Tag, 'drawregion') || strcmp(ax.Tag, 'finished')
                exitButton.Enable = 'off';
                xy{jj}  = hFH(jj).getPosition;
                jj = jj + 1;
            end
            undoButton.Enable = 'off';
            finishButton.Enable = 'on';

%             if strcmp(ax.Tag, 'finished')
%             end
            
            % writes all the information into the array
            image_data(i).imageNumber = img; 
            image_data(i).session = session; 
            image_data(i).userID = userID;
            image_data(i).age = age; 
            image_data(i).sex = sex; 
            image_data(i).xy = xy;

            %saves the array as a .mat file
%             outputfile = 'U:\CitSeg\results\';
            filename  = [inputoutputFile userID '.mat'];
            save(filename, 'image_data');
            
            %resets all the buttons
            undoButton.Enable = 'off';
            finishButton.Enable = 'off';
            f.MenuBar = 'figure';
            nextButton.String = 'DRAW REGION';
            infoBox.String{1} = 'Zoom in or out of image using the buttons at the top of the figure';
            infoBox.String{2} = 'Click DRAW REGION to draw around the spine';

        end
        close(f)
        if shutdown == 1 % breaks out of the for loop
            return
        end
       

    end
    
    if shutdown == 1 % breaks out of the for loop
        return
    end

% this joins previous saved data with this sessions saved data
 
if isempty(image_data_previousSession) == 0 
    image_data  = [image_data_previousSession, image_data]; 
end

%% this removes empty rows  --  just to make sure
empty_elems = arrayfun(@(s) all(structfun(@isempty,s)), image_data);
image_data(empty_elems) = [];
%%


% done = msgbox('well done you have finished with today''s set of images');

%% Final Save!!

% outputfile = 'U:\CitSeg\results\';
filename  = [inputoutputFile userID '.mat'];
save(filename, 'image_data');




end

%% this bit I have blanked out but can display the data in graphs

 %% FROM HERE IT NEEDS 1 TAB
% %--------------------------------
% % collates data from all the participent data files into 1 structure file
% % from .mat files 
% 
% 
% overallData = struct('name', {}, 'data', {}); 
% 
% data = 1; 
% 
% files1 = dir('*.mat'); 
% 
% for i = 1:length(files1)
%     overallData(i).name = files1(i).name; 
%     overallData(i).data = load(files1(i).name, 'image_data');
% end
% 
% %%
% %%
% % Plots the 'imageNumber' with all the participents on the same graph
% % in a for loop
% clc 
% clf
% cmap = colormap('lines');
% 
% x = {}; y = {}; 
%  
% 
% num_participents = length(overallData); 
% 
% for i = 1:num_participents
%     ax = subplot(2,2,i);
%     
%     
%     num_participent = length(overallData); 
%     hold on;
% 
% 
%     for j = 1:num_participent
%        
%         num_ROI = length(overallData(j).data.image_data(i).xy); 
%         for k = 1:num_ROI
%             x = overallData(j).data.image_data(i).xy{1,k}(:, 1); %#ok<*SAGROW>
%             y = overallData(j).data.image_data(i).xy{1,k}(:, 2);
%             pl = plot(x,y,'Color',cmap(j,:));
%             if (k~=1); set(get(get(pl,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); end;
%         end
%         get_name{j} = overallData(j).data.image_data(i).userID;        
%     end
% 
%     hold off;
% 
%     title(overallData(j).data.image_data(i).imageNumber);  
%     legend(get_name); 
% 
% end
%     