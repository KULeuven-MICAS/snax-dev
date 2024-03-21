from tests.cocotb.snax_util import gen_rand_int_list, transform_data, matrix_view

TRANSFORMATION_PARAMS = [
    # {
    #     "nb_elements": 16,
    #     "nb_for_loops": 1,
    #     "strides": [
    #         {
    #             "src": 1,
    #             "dst": 1,
    #             "bound": 16
    #         },
    #     ]
    # },
    # {
    #     "nb_elements": 16,
    #     "nb_for_loops": 2,
    #     "strides": [
    #         {
    #             "src": 1,
    #             "dst": 8,
    #             "bound": 2
    #         },
    #         {
    #             "src": 2,
    #             "dst": 1,
    #             "bound": 8
    #         },
    #     ]
    # },
    # {
    #     "nb_elements": 64,
    #     "nb_for_loops": 2,
    #     "strides": [
    #         {
    #             "src": 1,
    #             "dst": 8,
    #             "bound": 8
    #         },
    #         {
    #             "src": 8,
    #             "dst": 1,
    #             "bound": 8
    #         },
    #     ]
    # },
    # {
    #     "nb_elements": 16,
    #     "nb_for_loops": 3,
    #     "strides": [
    #         {
    #             "src": 8,
    #             "dst": 8,
    #             "bound": 2
    #         },
    #         {
    #             "src": 1,
    #             "dst": 4,
    #             "bound": 2
    #         },
    #         {
    #             "src": 2,
    #             "dst": 1,
    #             "bound": 4
    #         },
    #     ]
    # },
    # {
    #     "nb_elements": 64,
    #     "nb_for_loops": 4,
    #     "strides": [
    #         {
    #             "src": 32,
    #             "dst": 32,
    #             "bound": 2
    #         },
    #         {
    #             "src": 4,
    #             "dst": 16,
    #             "bound": 2
    #         },
    #         {
    #             "src": 8,
    #             "dst": 4,
    #             "bound": 4
    #         },
    #         {
    #             "src": 1,
    #             "dst": 1,
    #             "bound": 4
    #         },
    #     ]
    # },
    # # My Test Case
    # {
    #     "nb_elements": 16,
    #     "nb_for_loops": 2,
    #     "strides": [
    #         {
    #             "src": 1,
    #             "dst": 1,
    #             "bound": 16
    #         },
    #         {
    #             "src": 1,
    #             "dst": 1,
    #             "bound": 1
    #         },
    #     ]
    # },
    # Row-Major to Column-Major
    # [M2, M1, K2, K1] => [K2, K1, M2, M1]
    # M2 = 16, M1 = 1, K2 = 16, K1 = 1
    {
        "nb_elements": 256,
        "nb_for_loops": 4,
        "strides": [
            {
                "src": 1,
                "dst": 16,
                "bound": 16
            },
            {
                "src": 4,
                "dst": 64,
                "bound": 1
            },
            {
                "src": 16,
                "dst": 1,
                "bound": 16
            },
            {
                "src": 64,
                "dst": 4,
                "bound": 1
            },
        ] 
    },
    # Row-Major to Tile-Layout
    # [M2, M1, K2, K1] => [K2, K1, M2, M1]
    # M2 = 16, M1 = 1, K2 = 16, K1 = 1
    {
        "nb_elements": 512,
        "nb_for_loops": 4,
        "strides": [
            {
                "src": 1,
                "dst": 1,
                "bound": 8
            },
            {
                "src": 8,
                "dst": 64,
                "bound": 4
            },
            {
                "src": 32,
                "dst": 8,
                "bound": 8
            },
            {
                "src": 256,
                "dst": 256,
                "bound": 2
            },
        ]
    },
    # Row-Major to Tile-Layout
    {
        "nb_elements": 256,
        "nb_for_loops": 4,
        "strides": [
            {
                "src": 1,
                "dst": 1,
                "bound": 8
            },
            {
                "src": 16,
                "dst": 8,
                "bound": 8
            },
            {
                "src": 8,
                "dst": 64,
                "bound": 2
            },
            {
                "src": 128,
                "dst": 128,
                "bound": 2
            },
        ]
    },
    # Tile-Layout to Tile-Layout-Transposed
    {
        "nb_elements": 256,
        "nb_for_loops": 4,
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
            {
                "src": 64,
                "dst": 128,
                "bound": 2
            },
            {
                "src": 128,
                "dst": 64,
                "bound": 2
            },
        ]
    }
]


for params in TRANSFORMATION_PARAMS:
    input_addr = list(range(params["nb_elements"]))
    input_val = list(range(params["nb_elements"]))
    output_addr = transform_data(input_addr, params)
    print("[Input Addr]", input_addr)
    print("[Output Addr]", output_addr)

    # print(matrix_view(input_val, input_addr, params['src_shape']))
    # print(matrix_view(input_val, output_addr, params['dst_shape']))
