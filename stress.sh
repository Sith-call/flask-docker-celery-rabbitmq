for value in {1..50}
do
    curl --data '{json}' -H 'Content-Type: application/json' 0.0.0.0:8888/api/process_data
done
