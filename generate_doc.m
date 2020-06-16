%% HEADER
% This function crawls across the various folders of the project, and 
% create .md files. Each file contains the formatted documentation for 
% each function that is located under the folders.
% 
% Authors: Ryan Topfer, Alexandre D'Astous, Julien Cohen-Adad

%% Checkout gh-pages branch
% at this point in the pipeline, we are located in the root of the
% shimming-toolbox repository, under the master branch.
!git checkout -b gh-pages
% go into it if it previously failed, if not then it does not do anything
!git checkout gh-pages

%% Initial setup
cd ..
% Rename 's' folder to 'shimming-toolbox'
!mv s shimming-toolbox
% create new temp folder
% !mkdir temp
% Clone doc generation software
!git clone https://github.com/shimming-toolbox/helpDocMd.git
% Add various paths
addpath(genpath('./helpDocMd/src'))
addpath(genpath('./shimming-toolbox'))
% cd temp

%% API doc
% overwrite shimming-toolbox/docs/contributing/api_documentation/
!rm -r shimming-toolbox/docs/contributing/api_documentation
!mkdir shimming-toolbox/docs/contributing/api_documentation

% Generate API documentation
src = './shimming-toolbox';
outputPath = './shimming-toolbox/docs/contributing/api_documentation';

% Create dummy .md file
!mkdir shimming-toolbox/docs/contributing
!echo "Awesome!!!" > ./shimming-toolbox/docs/contributing/dummy.md
% Push to gh-pages branch
cd shimming-toolbox
!git add *
!git commit -m "Updated documentation"
!git push
cd ..
%% The following code needs to be uncommented once MATLAB 2020 is installed 
% on tristano
% src = Documentor.findfiles( src );
% 
% % Remove files not working
% src = src(~contains(src,'shimming-toolbox/Coils/Shim_Siemens/Shim_Prisma/ShimOpt_Prisma.m'));
% src = src(~contains(src,'shimming-toolbox/Coils/Shim_Siemens/Shim_Prisma/Shim_HGM_Prisma/ShimOpt_HGM_Prisma.m'));
% src = src(~contains(src,'shimming-toolbox/Coils/Shim_Siemens/Shim_Prisma/Shim_IUGM_Prisma_fit/ShimOpt_IUGM_Prisma_fit.m'));
% src = src(~contains(src,'shimming-toolbox/Ui/ShimUse.m'));
% 
% % Remove files not to be documented
% src = src(~contains(src,'shimming-toolbox/tests'));
% 
% % Call documentor
% Options.outputDir = './shimming-toolbox/docs/contributing/api_documentation';
% Dr = Documentor( src , Options ) ;
% 
% % Generate documentation
% Dr.printdoc() ;

% Update mkDocs.yml APIdoc navigation automatically using functions from
% @Documentor.printYml


%% README, LICENSE, etc

% Python script that (might as well be matlab at this point?) 
% - Reads current mkdocs.yml configuration file   Need YAML fix for names
% with spaces
% - Looks at shimming-toolbox for the appropriate files
% -- README will most likely need to be split up
% -- LICENSE (put where it says in mkdocs.yml)
% -- Other Ressources (Depending on if it's already in shimming-toolbox.org)
% - delete them from shimming-toolbox.org
% - Add them to shimming-toolbox.org

% manual?

%% branch
% cd shimming-toolbox.org
% !git add .
% !git commit -m"Update website"
% !git push -u origin update-website % (force merge on master eventually?)

%%
% Delete temp folder and all subfolders
% cd ..
% rmdir temp s
% 
% rmdir shimming-toolbox s
rmdir helpDocMd s
disp('done')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General purpose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Read Yaml file
% filepath = './shimming-toolbox/mkdocs.yml';
% configFile = yaml.ReadYaml(filepath);
% %% Write Yaml file
% % yaml stores the config file a a data structure, to do so, it needs to
% % remove the spacings from certain nav fields. The following function
% % finds those fields and adds the spaces back
% yaml.WriteYaml('./shimming-toolbox/mkdocs2.yml', configFile);
% keywords = {'Getting Started'; 'API Documentation'; 'Other Ressources'};
% correctSpacings('./shimming-toolbox/mkdocs2.yml', keywords)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function correctSpacings(filepath, keywords)
    
    % create cell array containing keyword without spaces
    for i = 1:numel(keywords)
        noSpacing{i,1} = keywords{i}(~isspace(keywords{i}));
    end
    
    % Read txt into cell A
    fileID = fopen(filepath,'r');
    i = 1;
    while ~feof(fileID)
        tline = fgetl(fileID);
        
        % In a line, look for each keywords
        for iKeyword = 1:numel(keywords)
             if(~isempty(strfind(tline,noSpacing{iKeyword})))
                 
                 keywordStarts = strfind(tline,noSpacing{iKeyword}) - 1;
                 
                 iSpace = 0;
                 newKeyword = keywords{iKeyword};
                 spaceInKeyword = strfind(newKeyword,' ') - 1 + iSpace;
                 while(~isempty(spaceInKeyword))
                     spaceInTline = keywordStarts + spaceInKeyword ;
                     tline = [tline(1:spaceInTline), ' ' ,  tline(spaceInTline+1:end)] ;
                     
                     newKeyword = [newKeyword(1:spaceInKeyword-iSpace),  newKeyword(spaceInKeyword+2-iSpace:end)]
                     iSpace = iSpace+1;
                     spaceInKeyword = strfind(newKeyword,' ') - 1 + iSpace;
                     
                 end
             end
        end

        newText{i} = tline;
        i = i+1;
    end
    fclose(fileID);
    
    % Write newText into txt
    fileID = fopen(filepath, 'w');
    for i = 1:numel(newText)
        if i == numel(newText)
            fprintf(fileID,'%s', newText{i});
            break
        else
            fprintf(fileID,'%s\n', newText{i});
        end
    end
    fclose(fileID);

end
