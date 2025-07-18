
# Wrapper для специализированной модели сегментации стен
class WallSegmentationModel:
    def __init__(self, model_path, config_path):
        self.model_path = model_path
        self.config = self.load_config(config_path)
        self.class_mapping = self.load_mapping()
    
    def load_config(self, config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    
    def load_mapping(self):
        with open('wall_segmentation_mapping.json', 'r') as f:
            return json.load(f)['class_mapping']
    
    def process_output(self, raw_output):
        """Преобразует выход ADE20K в бинарную маску стен"""
        # Применяем маппинг классов
        wall_mask = np.zeros_like(raw_output)
        for original_class, new_class in self.class_mapping.items():
            wall_mask[raw_output == original_class] = new_class
        return wall_mask
    
    def post_process(self, mask):
        """Постобработка маски стен"""
        # Убираем мелкие области
        if self.config['processing']['postprocessing']['filter_small_regions']:
            min_size = self.config['processing']['postprocessing']['min_region_size']
            # Здесь можно добавить фильтрацию мелких регионов
        
        return mask
