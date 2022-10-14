def test_resources(e2e_plan_runner):
  "Test that plan works and the numbers of resources is as expected."
  modules, resources = e2e_plan_runner()
  assert len(modules) > 0
  assert len(resources) > 0
