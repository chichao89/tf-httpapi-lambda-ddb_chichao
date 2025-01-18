#!/bin/bash

#INVOKE_URL="https://1anoj4sgcd.execute-api.ap-southeast-1.amazonaws.com"
#INVOKE_URL="$(terraform output -raw invoke_url)"
INVOKE_URL="https://topmovies.sctp-sandbox.com"

# add movies
echo "> add movies"
for i in $(seq 2011 2013); do
    json="$(jq -n --arg year "$i" --arg title "MovieTitle$i" '{year: $year, title: $title}')"
    curl \
        -X PUT \
        -H "Content-Type: application/json" \
        -d "$json" \
        "$INVOKE_URL/topmovies";
    echo
done

# get movies by year
echo "> get movies by year"
for i in $(seq 2011 2013); do
    curl "$INVOKE_URL/topmovies/$i"
    echo
done

# delete movie
echo "> delete movie from 2012"
curl -X DELETE "$INVOKE_URL/topmovies/2012"
echo

# get movies
echo "> get movies"
curl "$INVOKE_URL/topmovies"
