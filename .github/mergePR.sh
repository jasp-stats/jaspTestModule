owner_repo="$1"
author='weblate'

function getPRNumber()
{ 
  pr_list=$(gh pr list -R $owner_repo -A $author)
  first_line=$(echo "$pr_list" | sed -n '1p')
  number=$(echo "$first_line" | grep -oE '^[0-9]+')
  echo "$number"
}

pr_number="$(getPRNumber)"
if [ -z "$pr_number" ]
then
  echo "No Pull Request"
else
  echo "Pull Request ID: $pr_number"
  echo $(gh pr merge --squash $pr_number -R $owner_repo)
  
  pr_number="$(getPRNumber)"
  if [ -z "$pr_number" ]
  then
    echo "No other Pull Request"
  else
    echo "2nd Pull Request ID: $pr_number"
    echo $(gh pr merge --squash $pr_number -R $owner_repo)
  fi
fi
