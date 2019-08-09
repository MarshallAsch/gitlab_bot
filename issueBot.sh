#!/usr/bin/env node

/******************************************************************************************
 ******************************************************************************************
 *
 *
 * This script should be run by gitlab webhooks for Push events and merge request events.
 * It will automaticly move issues arround on the board
 *
 * - when there is a new branch
 * - when there is a new pull request
 * - when there is a closed pull request
 * - when there is a merged pull request
 *
 * This script is designed to be run from the https://github.com/MarshallAsch/CI_server server
 *
 ******************************************************************************************
 ******************************************************************************************/


const http = require('https');
const child  = require('child_process');
const yaml = require("js-yaml");
const fs = require("fs");


const configFile = fs.readFileSync("config.yaml", "utf8");
const config = yaml.load(configFile);


let type = process.argv[2]
let event = JSON.parse(process.argv[3]);

let projectId = event.project.id;


let project =  config.projects.find(e => e.id === projectId);

if (!project) {
	console.log(`project "${projectId}" not found in config file`);
	process.exit(0);
}


if (type === "push") {
	handlePush(event, project);
} else if (type === "merge_request") {
	handleMR(event, project);
}


function handlePush(event, config) {
	let before = event.before;
	let ref = event.ref;

	let parts = ref.split("/");
	let branch = parts[parts.length-1];


	// check if it is a new branch
	if (before.match(/^0+$/)) {
		console.log("new branch: " + branch)


		// check if the branch starts with a number
		if (branch.match(/^[0-9]+-/)) {
			parts = branch.split("-");
			let number = parts[0];

			console.log("possible ticket num: " + number)

			const options = {
				  headers: {
		    		'Private-Token': config.token,
		  		}
			};

			http.get(`https://gitlab.com/api/v4/projects/${config.id}/issues?iids[]=${number}`, options, (res) => {
				res.on('data', (d) => {
	    			let issues = JSON.parse(d.toString());

	    			if (issues.length != 0) {
	    				moveIssue(issues[0], config.token, config.new_branch.new_label, config.new_branch.old_labels);
	    			}
	  			});
			});
		}
	}
}

function handleMR(event, config) {
	let branch = event.object_attributes.source_branch;

	let state = event.object_attributes.state;

	let new_label = "";
	let old_labels = [];

	switch(state) {
		case "opened":
			new_label = config.opened_mr.new_label;
			old_labels = config.opened_mr.old_labels;
			break;
		case "closed":
			new_label = config.closed_mr.new_label;
			old_labels = config.closed_mr.old_labels;
			break;
		case "merged":
			new_label = config.merged_mr.new_label;
			old_labels = config.merged_mr.old_labels;
			break;
		default:
			console.log("don't handle this");
			return;
	}

	new_label = new_label || "";
	old_labels = old_labels || [];


	// check if the branch starts with a number
	if (branch.match(/^[0-9]+-/)) {
		parts = branch.split("-");
		let number = parts[0];

		console.log("possible ticket num: " + number)

		const options = {
			  headers: {
	    		'Private-Token': config.token,
	  		}
		};

		http.get(`https://gitlab.com/api/v4/projects/${config.id}/issues?iids[]=${number}`, options, (res) => {
			res.on('data', (d) => {
    			let issues = JSON.parse(d.toString());

    			if (issues.length != 0) {
    				moveIssue(issues[0], config.token, new_label, old_labels);
    			}
  			});
		});
	}
}

function moveIssue(issue, token, addLabel, removeLabels) {

	let labels = issue.labels;

	if (!labels.includes(addLabel)) {
		labels.push(addLabel);
	}

	labels = labels.filter(e => !removeLabels.includes(e))

	let res = child.execSync(`curl --request PUT --header "PRIVATE-TOKEN: ${token}" https://gitlab.com/api/v4/projects/${issue.project_id}/issues/${issue.iid}?labels=${labels.join()}`);
	res = JSON.parse(res);

	console.log(res);
}






