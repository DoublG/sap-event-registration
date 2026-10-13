// pathways app: the learning-track catalogue (read-mostly).
namespace coderdojo.pathways;

using { cuid } from '@sap/cds/common';
using { coderdojo.ImagePath, coderdojo.OrganisationContent } from './common';

entity Skills : cuid, OrganisationContent {
        name     : localized String(100) @mandatory; // unique
        pathways : Association to many PathwaySkills on pathways.skill = $self;
}

entity Pathways : cuid, OrganisationContent {
        name               : localized String(200) @mandatory;
        subtitle           : localized String(300);
        description        : localized LargeString;
        image              : ImagePath;
        minAge             : Integer;
        maxAge             : Integer;
        noExperienceNeeded : Boolean default true;
        runsInBrowser      : Boolean default false;
        skills             : Composition of many PathwaySkills on skills.pathway = $self;
        steps              : Composition of many PathwaySteps on steps.pathway = $self;
        projects           : Composition of many PathwayProjects on projects.pathway = $self;
}

entity PathwaySkills {
    key pathway : Association to Pathways;
    key skill   : Association to Skills;
}

entity PathwaySteps : cuid, OrganisationContent {
        pathway     : Association to Pathways @mandatory;
        order       : Integer default 0;
        title       : localized String(200) @mandatory;
        description : localized LargeString;
}

entity PathwayProjects : cuid, OrganisationContent {
        pathway     : Association to Pathways @mandatory;
        title       : localized String(200) @mandatory;
        description : localized LargeString;
}

annotate Skills with @assert.unique: { name: [name] };
