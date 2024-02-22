from tests.cocotb.snax_util import gen_rand_int_list, transform_data

TRANSFORMATION_PARAMS = [
    {
        "nb_elements": 16,
        "nb_for_loops": 1,
        "strides": [
            {
                "src": 1,
                "dst": 1,
                "bound": 16
            },
        ]
    },
    {
        "nb_elements": 16,
        "nb_for_loops": 2,
        "strides": [
            {
                "src": 1,
                "dst": 8,
                "bound": 2
            },
            {
                "src": 2,
                "dst": 1,
                "bound": 8
            },
        ]
    },
    {
        "nb_elements": 64,
        "nb_for_loops": 2,
        "strides": [
            {
                "src": 1,
                "dst": 8,
                "bound": 8
            },
            {
                "src": 8,
                "dst": 1,
                "bound": 8
            },
        ]
    },
    {
        "nb_elements": 16,
        "nb_for_loops": 3,
        "strides": [
            {
                "src": 8,
                "dst": 8,
                "bound": 2
            },
            {
                "src": 1,
                "dst": 4,
                "bound": 2
            },
            {
                "src": 2,
                "dst": 1,
                "bound": 4
            },
        ]
    },
        {
        "nb_elements": 64,
        "nb_for_loops": 4,
        "strides": [
            {
                "src": 32,
                "dst": 32,
                "bound": 2
            },
            {
                "src": 4,
                "dst": 16,
                "bound": 2
            },
            {
                "src": 8,
                "dst": 4,
                "bound": 4
            },
            {
                "src": 1,
                "dst": 1,
                "bound": 4
            },
        ]
    },
]


for params in TRANSFORMATION_PARAMS:
    input = list(range(params["nb_elements"]))
    output = transform_data(input, params)
    print()

    print(input)
    print(output)
