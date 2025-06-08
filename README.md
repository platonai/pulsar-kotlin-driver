The driver to access the pulsar service.

Submit an X-SQL to scrape:

    val sql = "..."
    val id = driver.submit(sql, asap = true)

Check the status of a scrape task:

    val status = driver.findById(id)

Check our dashboard:

    val dashboard = driver.dashboard()

Download all scrape results page by page:

    val results = driver.download(pageSize = 10)
