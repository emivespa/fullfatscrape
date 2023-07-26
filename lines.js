const dotenv = require("dotenv");
const fs = require("fs");
const path = require("path");
const uuid = require("uuid");

const timestamp = require("./timestamp.js");

dotenv.config();
const {
	JSON_FOLDER_PATH,
	OPENSEARCH_INDEX_NAME,
	// HACK: should eventually provide channelMetadata in some other way.
	CHANNEL_HANDLE,
	CHANNEL_ID,
	CHANNEL_LEGACY_USERNAME,
	CHANNEL_USERNAME,
} = process.env;

////////////////////////////////////////////////////////////////////////////////

const buildBulkRequestLines = () => {
	new Promise((resolve, reject) => {
		let bulkRequestLines = [];
		fs.readdir(JSON_FOLDER_PATH, (err, files) => {
			if (err) {
				reject(err);
			}
			const jsonFiles = files.filter(
				(file) =>
					path.extname(file).toLowerCase() ===
					".json"
			);
			jsonFiles.forEach((file) => {
				const fileContents = fs.readFileSync(
					path.join(JSON_FOLDER_PATH, file),
					"utf8"
				);
				const jsonArray = JSON.parse(fileContents);

				const videoBasename = path.basename(
					file,
					".json"
				);
				const [, videoTitle, videoId] =
					videoBasename.match(
						/(.*) \[(.{11})\]$/
					);
				jsonArray.forEach((item) => {
					const ts = timestamp(item.start);
					const id = `${CHANNEL_ID}:${videoId}:${ts}:${uuid.v4()}`;
					// There should not be any repeat channel:video:ts tuples, but add a uuid just in case.
					const link = `https://www.youtube.com/watch?v=${videoId}&t=${timestamp(
						item.start
					)}`;
					const indexStuff = {
						index: {
							_index: OPENSEARCH_INDEX_NAME,
							_id: id,
						},
					};
					const doc = {
						id: id,
						channelId: CHANNEL_ID,
						channelHandle: CHANNEL_HANDLE,
						channelLegacyUsername:
							CHANNEL_LEGACY_USERNAME,
						channelUsername:
							CHANNEL_USERNAME,
						videoId: videoId,
						videoTitle: videoTitle,
						text: item.line,
						timestamp: ts,
						link: link,
					};
					bulkRequestLines.push(
						JSON.stringify(indexStuff)
					);
					bulkRequestLines.push(
						JSON.stringify(doc)
					);
				});
			});
			resolve(bulkRequestLines);
		});
	});
};

const main = async () => {
	const bulkRequestLines = buildBulkRequestLines();
	const step = 15000;
	for (let i = 0; ; i++) {
		let bulkRequestBody = "";
		let start = i * step;
		let end = (i + 1) * step;
		let slice = bulkRequestLines.slice(start, end);
		if (slice.length === 0) {
			break;
		}
		slice.forEach((l) => (bulkRequestBody += l + "\n"));
		fs.writeFile(`./bulk/${i}.bulk`, bulkRequestBody, (err) => {
			if (err) throw err;
			console.log("The file has been saved!");
		});
	}
};
main().catch(console.error);
