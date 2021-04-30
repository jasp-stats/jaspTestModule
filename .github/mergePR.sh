put_url="https://api.github.com/repos/$OWNER/$REPO/pulls/$PULL_ID/merge"
echo "${put_url}"
curl_reply=$(curl \
	-X PUT \
	$put_url \
	-d '{"commit_title":"myCommit", "merge_method": "squash"}' \
       	-H "Authorization: Bearer $TOKEN")
echo "$curl_reply"
