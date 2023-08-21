import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--simulator",
        dest="simulator",
        default="verilator",
        help="simulator used by cocotb",
    )


@pytest.fixture
def simulator(request):
    return request.config.getoption("--simulator")
