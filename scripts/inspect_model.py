import tensorflow.compat.v1 as tf

def inspect_graph(graph_def_file):
    """
    Загружает "замороженный граф" и выводит информацию о его узлах (операциях),
    чтобы помочь найти правильные имена входных и выходных тензоров.
    """
    print(f"--- Анализ графа: {graph_def_file} ---")
    
    with tf.gfile.GFile(graph_def_file, "rb") as f:
        graph_def = tf.GraphDef()
        graph_def.ParseFromString(f.read())

    with tf.Graph().as_default() as graph:
        tf.import_graph_def(graph_def, name="")

    print("\n--- Список всех узлов (операций) в графе: ---")
    for op in graph.get_operations():
        # Нас особенно интересуют узлы типа "Placeholder", так как они часто являются входами
        if op.type == "Placeholder":
            print(f"--- НАЙДЕН ВХОД (Placeholder): Имя операции: '{op.name}', Тип: {op.type}, Выходы: {op.outputs}")
        else:
            # Печатаем другие узлы для общего контекста
            # print(f"Имя операции: '{op.name}', Тип: {op.type}")
            pass

    print("\n--- Пожалуйста, найдите имя операции-плейсхолдера выше и используйте его как 'input_arrays' (добавив ':0'). ---")
    print("--- Выходной узел часто называется 'SemanticPredictions' или что-то похожее. ---")


if __name__ == '__main__':
    # Путь к файлу модели внутри контейнера Docker
    model_path = 'deeplabv3_mnv2_ade20k_train_2018_12_03/frozen_inference_graph.pb'
    inspect_graph(model_path) 