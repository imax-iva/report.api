defmodule Report.Integration.MainStatsTest do
  use Report.Web.ConnCase

  alias Report.Stats.HistogramStatsRequest
  alias Report.Stats.MainStats
  use Timex

  test "get_main_stats/1" do
    insert_fixtures()

    {:ok, main_stats} = MainStats.get_main_stats()
    schema =
      "test/data/stats/main_stats_response.json"
      |> File.read!()
      |> Poison.decode!()

    schema = Map.put(schema, "properties", get_in(schema, ~w(properties data properties)))
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert %{"msps" => 3, "doctors" => 2, "declarations" => 1} = main_stats
  end

  test "get_division_stats/1" do
    %{"division" => division} = insert_fixtures()
    division_id = division.id

    {:ok, main_stats} = MainStats.get_division_stats(division_id)
    schema =
      "test/data/stats/division_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert %{
      "division" => %{id: ^division_id},
      "stats" => %{
        "declarations" => 1,
        "msps" => 1,
        "doctors" => 1,
      }
    } = main_stats
  end

  test "get_regions_stats/1" do
    %{"region" => region} = insert_fixtures()
    region_id = region.id

    {:ok, main_stats} = MainStats.get_regions_stats(region_id)
    schema =
      "test/data/stats/regions_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert %{
      "region" => %{id: ^region_id},
      "stats" => %{
        "declarations" => 1,
        "msps" => 1,
        "doctors" => 2,
      }
    } = main_stats
  end

  test "get_histogram_stats/1" do
    insert_fixtures()
    now = Timex.now

    # by "DAY" interval
    from_date =
      now
      |> Timex.shift(days: -20)
      |> Timex.format!("%F", :strftime)
    to_date = to_string(Date.utc_today())

    interval = HistogramStatsRequest.interval(:day)
    {:ok, main_stats} = MainStats.get_histogram_stats(%{
      "from_date" => from_date,
      "to_date" => to_date,
      "interval" => interval,
    })
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    schema =
      schema
      |> Map.put("type", "array")
      |> Map.put("items", schema["properties"]["data"]["items"])
      |> Map.delete("properties")
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)
    assert 21 = Enum.count(main_stats)
    assert %{
      "period_type" => ^interval,
      "period_name" => ^from_date,
    } = List.first(main_stats)
    assert %{
      "period_type" => ^interval,
      "period_name" => ^to_date,
    } = List.last(main_stats)
    assert %{
      "declarations_created" => 2,
      "declarations_closed" => 1,
      "declarations_active_start" => 0,
      "declarations_active_end" => 1} = main_stats |> List.last

    # by "MONTH" interval
    interval = HistogramStatsRequest.interval(:month)
    from_date =
      now
      |> Timex.beginning_of_month()
      |> Timex.format!("%F", :strftime)
    to_date =
      now
      |> Timex.end_of_month()
      |> Timex.format!("%F", :strftime)
    {:ok, main_stats} = MainStats.get_histogram_stats(%{
      "from_date" => from_date,
      "to_date" => to_date,
      "interval" => interval
    })
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    schema =
      schema
      |> Map.put("type", "array")
      |> Map.put("items", schema["properties"]["data"]["items"])
      |> Map.delete("properties")
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert 1 = Enum.count(main_stats)
    from_month =
      now
      |> Timex.beginning_of_month()
      |> Timex.format!("%Y-%m", :strftime)
    to_month =
      now
      |> Timex.end_of_month()
      |> Timex.format!("%Y-%m", :strftime)
    assert %{
      "period_type" => ^interval,
      "period_name" => ^from_month,
    } = List.first(main_stats)
    assert %{
      "period_type" => ^interval,
      "period_name" => ^to_month,
    } = List.last(main_stats)
    assert %{
      "declarations_created" => 2,
      "declarations_closed" => 1,
      "declarations_active_start" => 0,
      "declarations_active_end" => 1} = main_stats |> List.last

    # by "YEAR" interval
    interval = HistogramStatsRequest.interval(:year)
    from_date =
      now
      |> Timex.beginning_of_year()
      |> Timex.format!("%F", :strftime)
    to_date =
      now
      |> Timex.end_of_year()
      |> Timex.format!("%F", :strftime)
    {:ok, main_stats} = MainStats.get_histogram_stats(%{
      "from_date" => from_date,
      "to_date" => to_date,
      "interval" => interval
    })
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    schema =
      schema
      |> Map.put("type", "array")
      |> Map.put("items", schema["properties"]["data"]["items"])
      |> Map.delete("properties")
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert 1 = Enum.count(main_stats)
    from_year =
      now
      |> Timex.beginning_of_year()
      |> Timex.format!("%Y", :strftime)
    to_year =
      now
      |> Timex.end_of_year()
      |> Timex.format!("%Y", :strftime)
    assert %{
      "period_type" => ^interval,
      "period_name" => ^from_year,
    } = List.first(main_stats)
    assert %{
      "period_type" => ^interval,
      "period_name" => ^to_year,
    } = List.last(main_stats)
    assert %{
      "declarations_created" => 2,
      "declarations_closed" => 1,
      "declarations_active_start" => 0,
      "declarations_active_end" => 1} = main_stats |> List.last
  end

  test "histogram_stats_skeleton/2" do
    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-01-10],
      interval: HistogramStatsRequest.interval(:day)
    }
    skeleton = MainStats.histogram_stats_skeleton(request)
    assert 10 == Enum.count(skeleton)

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-05-10],
      interval: HistogramStatsRequest.interval(:month)
    }
    skeleton = MainStats.histogram_stats_skeleton(request)
    assert 5 == Enum.count(skeleton)

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-01-10],
      interval: HistogramStatsRequest.interval(:month)
    }
    skeleton = MainStats.histogram_stats_skeleton(request)
    assert 1 == Enum.count(skeleton)
    assert [%{
      "period_type" => "MONTH",
      "period_name" => "2017-01"
    }] = skeleton

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-05-10],
      interval: HistogramStatsRequest.interval(:year)
    }
    skeleton = MainStats.histogram_stats_skeleton(request)
    assert 1 == Enum.count(skeleton)
  end

  defp insert_fixtures do
    region = insert(:region)
    insert(:region, name: "ЧЕРКАСЬКА")
    person = insert(:person)
    insert(:legal_entity, addresses: [
      %{"zip": "02091", "area": "ЧЕРКАСЬКА",
        "type": "REGISTRATION", "region": "УМАНСЬКИЙ",
        "street": "вул. Ніжинська", "country": "UA",
        "building": "15", "apartment": "23",
        "settlement": "УМАНЬ", "street_type": "STREET",
        "settlement_id": "607dbc55-cb6b-4aaa-97c1-2a1e03476100",
        "settlement_type": "CITY"}
    ])
    legal_entity = insert(:legal_entity, addresses: [
      %{"zip": "02090", "area": "ЛЬВІВСЬКА",
        "type": "REGISTRATION", "region": "ПУСТОМИТІВСЬКИЙ",
        "street": "вул. Ніжинська", "country": "UA",
        "building": "15", "apartment": "23",
        "settlement": "СОРОКИ-ЛЬВІВСЬКІ", "street_type": "STREET",
        "settlement_id": "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
        "settlement_type": "CITY"},
    ])
    division = insert(:division, legal_entity_id: legal_entity.id)
    employee = insert(:employee,
      employee_type: "DOCTOR",
      division: division,
      legal_entity_id: legal_entity.id
    )
    insert(:employee, employee_type: "DOCTOR", legal_entity_id: legal_entity.id)
    insert(:employee)
    insert(:legal_entity)
    declaration1 = insert(:declaration,
      employee_id: employee.id,
      person_id: person.id,
      legal_entity_id: legal_entity.id,
      division_id: division.id,
      status: "active",
    )
    declaration2 = insert(:declaration,
      employee_id: employee.id,
      person_id: person.id,
      legal_entity_id: legal_entity.id,
      division_id: division.id,
      status: "terminated",
    )
    insert(:declaration_status_hstr, declaration_id: declaration1.id, status: declaration1.status)
    insert(:declaration_status_hstr, declaration_id: declaration2.id, status: "active")
    insert(:declaration_status_hstr, declaration_id: declaration2.id, status: declaration2.status)
    %{
      "region" => region,
      "division" => division,
      "legal_entity" => legal_entity,
      "employee" => employee,
      "declarations" => [
        declaration1,
        declaration2,
      ],
    }
  end
end
