---
layout: post
title: 'Taming APIs and Data Workflows with Airflow: A Developer’s Tale'
date: 2024-12-11 14:43 +0100
tags: ["apache-airflow", "data-pipelines", "workflow-automation", "api-integration", "python", "bash-scripting", "docker", "docker-compose", "data-engineering", "cloud-computing", "etl", "automation"]
categories: pipeline airflow
comments: true
author: "Marcel Fenerich"
---

## Transforming a Bash Script into an Airflow DAG: Automating AEMET Data Downloads

When I first set out to download weather data from the AEMET OpenData API, I thought, "Why not use a simple Bash script?" After all, Bash scripts are great for quick automation tasks, and I had a clear plan: loop through years and months, fetch data, and save it to a CSV. But what I hadn't accounted for were the many challenges lurking in the world of API calls and large datasets. Let me take you on this journey of learning, improvement, and automation with **Apache Airflow**.

---

## The Bash Script: A Good Start with Hidden Challenges

The script worked... sort of. It iterated through dates, fetched data, and processed it into a neat CSV file. But the problems became evident very quickly:

- **API Rate Limits**: My eager loops bombarded the API with calls, leading to temporary bans.
- **Error Handling**: What happens if the API returns malformed data? Or worse, no data at all?
- **Performance**: The script was single-threaded and slow. With years of data to fetch, the process became painfully tedious.
- **Maintainability**: Scaling the script for new requirements, like retries or better scheduling, quickly turned into a nightmare.

Here's a snippet of what the Bash script looked like:

```bash
# Fetch data for a specific month and year
fetch_data() {
    local year=$1
    local month=$2
    echo "Fetching data for $year-$month..."
}
```

Here’s the full Bash script I initially wrote:

{% gist mfenerich/dda71667aece2fcb315c3eccdb42ccf0 %}

It worked, but it wasn't future-proof. Clearly, I needed something more robust. Enter **Apache Airflow**.

---

## Why Airflow?

Apache Airflow is a workflow orchestrator. It lets you define workflows as Directed Acyclic Graphs (DAGs), with each step being an independent, reusable task. Here's why it was a perfect fit for my project:

- **Retry Mechanisms**: Automatic retries for failed tasks. No more manual re-runs!
- **Task Parallelism**: Download multiple months of data simultaneously, significantly speeding up the process.
- **Visibility**: A web interface to monitor tasks, logs, and execution history.
- **Extensibility**: Adding new features or modifying workflows is easy.

---

## Setting Up Airflow with Docker Compose

To get started with Airflow, I used Docker Compose for an easy and portable setup. Here’s how you can do the same:

1. **Download the `docker-compose.yaml` File**:

   ```bash
   curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.10.3/docker-compose.yaml'
   ```

2. **Create Necessary Directories**:

   Airflow requires several directories for its operation:

   - `./dags`: Place your DAG files here.
   - `./logs`: Contains logs from task execution and the scheduler.
   - `./config`: Add custom log parsers or `airflow_local_settings.py` to configure cluster policies.
   - `./plugins`: Add your custom plugins here.
   - `./output`: Save the flow’s file outputs here.

   Create these directories and set the correct user permissions:

   ```bash
   mkdir -p ./dags ./logs ./plugins ./config ./output
   echo -e "AIRFLOW_UID=$(id -u)" > .env
   ```

## Adding Output Mapping in Airflow's Docker Compose Configuration

To ensure your Airflow setup properly maps output files to a directory on your host machine, you’ll need to manually add the following line to your `docker-compose.yaml` file under the `volumes` section of each Airflow-related service:

```yaml
${AIRFLOW_PROJ_DIR:-.}/output:/opt/airflow/output
```

### Why Add This?

By default, the provided `docker-compose.yaml` configuration doesn’t include mapping for an `output` directory. This mapping allows Airflow to save files generated during workflows (like your processed data or intermediate results) directly to a folder on your host machine for easy access.

### Steps to Add the Mapping

1. Open the `docker-compose.yaml` file you downloaded or created.
2. Locate the `volumes` section under each Airflow service (e.g., `airflow-webserver`, `airflow-scheduler`, `airflow-worker`, etc.).
3. Add the following line to the list of `volumes`:

   ```yaml
   ${AIRFLOW_PROJ_DIR:-.}/output:/opt/airflow/output
   ```

4. Ensure the `output` directory exists on your host machine. You can create it with:

   ```bash
   mkdir -p ./output
   ```

### Example of Modified Volumes Section

Here’s an example for the `airflow-webserver` service:

```yaml
  airflow-webserver:
    <<: *airflow-common
    command: webserver
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: always
    depends_on:
      <<: *airflow-common-depends-on
      airflow-init:
        condition: service_completed_successfully
    volumes:
      - ${AIRFLOW_PROJ_DIR:-.}/dags:/opt/airflow/dags
      - ${AIRFLOW_PROJ_DIR:-.}/logs:/opt/airflow/logs
      - ${AIRFLOW_PROJ_DIR:-.}/config:/opt/airflow/config
      - ${AIRFLOW_PROJ_DIR:-.}/plugins:/opt/airflow/plugins
      - ${AIRFLOW_PROJ_DIR:-.}/output:/opt/airflow/output
```

### Verify the Mapping

After starting Airflow with `docker compose up`, verify that files saved in `/opt/airflow/output` inside the container are accessible in the `output` directory on your host machine.

This step ensures your workflow outputs are preserved and easily accessible outside the container, making debugging and data management much simpler.

1. **Initialize the Database**:

   Airflow requires database migrations and a first user account. Run the following command to initialize:

   ```bash
   docker compose up airflow-init
   ```

2. **Run Airflow**:

   Start all services using Docker Compose:

   ```bash
   docker compose up
   ```

   Once everything is running, you can access the Airflow UI at [http://localhost:8080/](http://localhost:8080/).

   - **Username**: `airflow`
   - **Password**: `airflow`

   This is the default administrator account created during the setup process. You can use it to log in and start exploring the UI. For detailed setup instructions, refer to the [official Airflow documentation](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html).

## From Bash to DAG: The Transformation

With Airflow set up, I transformed my Bash script into a DAG. Each step of the original script became an independent task in the DAG:

1. **Fetch the API URL**: Use Airflow’s `HttpHook` to call the API and extract the `datos` URL.
2. **Sensor for Data Availability**: Wait until the data is available for download using a `PythonSensor`.
3. **Process and Save Data**: Fetch the JSON data, process it, and append it to a CSV.

Here’s a simplified version of the DAG:

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.sensors.python import PythonSensor
from datetime import datetime, timedelta

with DAG(
    dag_id="fetch_aemet_data",
    schedule_interval=None,
    start_date=datetime(2024, 12, 1),
    catchup=False,
) as dag:

    fetch_task = PythonOperator(
        task_id="fetch_data",
        python_callable=fetch_data_function,
        op_kwargs={"year": 2024, "month": 12},
    )

    wait_task = PythonSensor(
        task_id="wait_for_data",
        python_callable=check_data_availability_function,
    )

    process_task = PythonOperator(
        task_id="process_data",
        python_callable=process_data_function,
    )

    fetch_task >> wait_task >> process_task
```

## The Advantages of Airflow

After the transition, everything changed for the better:

- **Scalability**: Airflow handles task scheduling and parallelism. I could now download data for multiple months simultaneously.
- **Reliability**: Built-in retries and error handling saved me from constant babysitting.
- **Reusability**: Tasks like `fetch_data` and `process_data` are modular and easy to extend.
- **Observability**: The Airflow UI provided a clear view of what was happening at every step.

---

## Explaining the Code: Why I Chose These Airflow Components

This DAG (`fetch_aemet_data_with_sensor`) automates the process of fetching, verifying, and processing weather data from the AEMET API. Here's a breakdown of the key components and why I used them:

---

### **1. Setting Up the DAG**

The DAG is defined using the `with` statement, ensuring proper scoping of the tasks. The `default_args` dictionary specifies:

- **Retries**: If a task fails, it retries once after a 5-minute delay.
- **Start Date**: Tasks can only run after this date.
- **Catchup**: Disabled to prevent backfilling tasks for past dates when the DAG wasn’t active.

This structure ensures the DAG runs efficiently and handles intermittent errors gracefully.

---

### **2. Fetching the API Data**

#### **The `fetch_data` Task**

This task retrieves the `datos` URL for the requested date range using Airflow’s `HttpHook`.

**Why use `HttpHook`?**

- It simplifies making HTTP requests and integrates seamlessly with Airflow’s connection management.
- The `http_conn_id` allows secure storage of API credentials in Airflow’s connections interface.

Key highlights of the function:

- Validates the API response and raises errors for missing or invalid `datos` URLs.
- Logs relevant information for debugging.

---

### **3. The Sensor: Waiting for Data Availability**

#### **The `check_data_availability` Task**

This task uses a `PythonSensor` to check if the `datos` URL is accessible. Sensors are ideal for waiting on external conditions, like data availability.

**Why use a sensor?**

- The sensor continuously polls the API until the data is available or a timeout is reached.
- This ensures the workflow doesn’t proceed until the required data is ready, avoiding potential errors in downstream tasks.

**Configuration:**

- **Timeout**: Stops polling after 60 seconds.
- **Poke Interval**: Checks the URL every 5 seconds.
- **Mode**: Uses the default "poke" mode for simplicity.

---

### **4. Processing the Data**

#### **The `process_data` Task**

This task fetches the actual data from the `datos` URL, processes it, and appends it to a CSV file.

**Key Features:**

- Ensures consistent headers in the CSV by checking the schema of the first record.
- Validates the structure of the data, logging warnings for any inconsistencies.
- Handles edge cases, like empty records or malformed JSON.

**Why use CSV output?**

- CSVs are lightweight and widely supported, making them an ideal format for storing structured data locally.

---

### **5. Task Dependencies**

The workflow follows this sequence:

1. **Fetch the URL**: Ensures the `datos` URL is retrieved successfully.
2. **Wait for Data**: Ensures the data at the `datos` URL is available before proceeding.
3. **Process the Data**: Fetches and processes the data.

**How dependencies are defined:**

- `fetch_task >> sensor_task >> process_task` ensures the tasks execute in the correct order, maintaining the logical flow.

---

### **6. Why Use Variables?**

The `Variable.get` method retrieves configuration values like the output directory. Using Airflow variables allows:

- Centralized management of settings.
- Flexibility to update configurations without modifying the code.

---

### **7. Hardcoded Years and Months**

For simplicity, I hardcoded the years and months. In a production setup, this could be dynamic, allowing users to specify the date range as parameters when triggering the DAG.

---

### **Advantages of This Approach**

- **Resilience**: Sensors and retries ensure the workflow can recover from temporary API issues.
- **Scalability**: Tasks for each month and year are defined dynamically, making the DAG adaptable to varying data requirements.
- **Modularity**: Each function handles a specific responsibility, making the code easier to maintain and extend.
- **Traceability**: Logging at each step provides visibility into the workflow, simplifying debugging.

---

## Full Code Example

For those interested in the complete implementation, here's the full code for the Airflow DAG:

{% gist mfenerich/b7a332f65e2db1f88d30c9a177bf96b0 %}

This code is ready to be used in your Airflow setup. Feel free to adapt it to your specific needs or let me know if you encounter any challenges!

### **Final Thoughts**

This DAG demonstrates how to build a robust, maintainable workflow using Airflow. By combining sensors, dynamic task generation, and modular functions, it handles real-world challenges like data availability and API errors gracefully. Let me know if you have any questions or suggestions for improvement! 🚀

## Lessons Learned

1. **Start Simple**: The Bash script was a good starting point. It helped me understand the problem and identify pain points.
2. **Invest in Better Tools**: Choosing the right tool for the job (Airflow) saved me countless hours.
3. **Iterative Improvements**: The migration to Airflow was gradual. I didn’t throw away the Bash script overnight; I built upon it.

---

## Final Thoughts

The journey from Bash to Airflow wasn’t just about improving a script; it was about rethinking the process entirely. Airflow gave me the power to scale, monitor, and optimize my workflow in ways I hadn’t imagined. If you’re managing complex workflows, consider giving Airflow a try. And remember, every automation journey begins with a simple script.

Got questions or a similar story to share? Drop them in the comments—I’d love to hear from you! 🚀
