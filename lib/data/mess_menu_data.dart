// Mess menu data structure
// Format: week -> day -> meal -> preference -> items
final Map<String, Map<String, Map<String, Map<String, List<String>>>>>
    messMenu = {
  "1st_3rd": {
    "Monday": {
      "breakfast": {
        "veg": ["Poha", "Bread & Jam", "Tea/Coffee"],
        "nonVeg": ["Poha", "Bread & Jam", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Sabzi", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Curry", "Salad"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Paneer Curry", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Fish Fry", "Salad"],
      },
    },
    "Tuesday": {
      "breakfast": {
        "veg": ["Idli", "Sambar", "Chutney", "Tea/Coffee"],
        "nonVeg": ["Idli", "Sambar", "Chutney", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Aloo Gobi", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Mutton Curry", "Curd"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Mix Veg", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Masala", "Salad"],
      },
    },
    "Wednesday": {
      "breakfast": {
        "veg": ["Upma", "Bread & Butter", "Tea/Coffee"],
        "nonVeg": ["Upma", "Bread & Butter", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Rajma", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Egg Curry", "Salad"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Chana Masala", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Fish Curry", "Curd"],
      },
    },
    "Thursday": {
      "breakfast": {
        "veg": ["Dosa", "Sambar", "Chutney", "Tea/Coffee"],
        "nonVeg": ["Dosa", "Sambar", "Chutney", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Palak Paneer", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Biryani", "Raita"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Veg Kofta", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Curry", "Salad"],
      },
    },
    "Friday": {
      "breakfast": {
        "veg": ["Paratha", "Curd", "Pickle", "Tea/Coffee"],
        "nonVeg": ["Paratha", "Curd", "Pickle", "Omelette", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Baingan Bharta", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Mutton Curry", "Curd"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Kadai Paneer", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Fish Fry", "Salad"],
      },
    },
    "Saturday": {
      "breakfast": {
        "veg": ["Poori", "Aloo Sabzi", "Tea/Coffee"],
        "nonVeg": ["Poori", "Aloo Sabzi", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Mixed Veg", "Sweet", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Fry", "Sweet", "Salad"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Paneer Butter Masala", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Masala", "Curd"],
      },
    },
    "Sunday": {
      "breakfast": {
        "veg": ["Bread Pakora", "Chutney", "Tea/Coffee"],
        "nonVeg": ["Bread Pakora", "Chutney", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Veg Pulao", "Raita", "Sweet"],
        "nonVeg": ["Dal", "Rice", "Roti", "Egg Biryani", "Raita", "Sweet"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Shahi Paneer", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Fish Curry", "Salad"],
      },
    },
  },
  "2nd_4th": {
    "Monday": {
      "breakfast": {
        "veg": ["Upma", "Bread & Jam", "Tea/Coffee"],
        "nonVeg": ["Upma", "Bread & Jam", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Gobi Masala", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Fry", "Salad"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Aloo Matar", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Mutton Curry", "Curd"],
      },
    },
    "Tuesday": {
      "breakfast": {
        "veg": ["Dosa", "Sambar", "Chutney", "Tea/Coffee"],
        "nonVeg": ["Dosa", "Sambar", "Chutney", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Bhindi Masala", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Egg Curry", "Salad"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Kadai Veg", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Fish Fry", "Curd"],
      },
    },
    "Wednesday": {
      "breakfast": {
        "veg": ["Poha", "Bread & Butter", "Tea/Coffee"],
        "nonVeg": ["Poha", "Bread & Butter", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Palak Paneer", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Curry", "Salad"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Mix Veg", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Masala", "Salad"],
      },
    },
    "Thursday": {
      "breakfast": {
        "veg": ["Idli", "Sambar", "Chutney", "Tea/Coffee"],
        "nonVeg": ["Idli", "Sambar", "Chutney", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Rajma", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Mutton Curry", "Curd"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Paneer Curry", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Fish Curry", "Salad"],
      },
    },
    "Friday": {
      "breakfast": {
        "veg": ["Paratha", "Curd", "Pickle", "Tea/Coffee"],
        "nonVeg": ["Paratha", "Curd", "Pickle", "Omelette", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Baingan Bharta", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Biryani", "Raita"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Kadai Paneer", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Fry", "Curd"],
      },
    },
    "Saturday": {
      "breakfast": {
        "veg": ["Poori", "Chole", "Tea/Coffee"],
        "nonVeg": ["Poori", "Chole", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Veg Kofta", "Sweet", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Mutton Curry", "Sweet", "Salad"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Shahi Paneer", "Salad"],
        "nonVeg": ["Dal", "Rice", "Roti", "Fish Fry", "Salad"],
      },
    },
    "Sunday": {
      "breakfast": {
        "veg": ["Bread Pakora", "Chutney", "Tea/Coffee"],
        "nonVeg": ["Bread Pakora", "Chutney", "Boiled Eggs", "Tea/Coffee"],
      },
      "lunch": {
        "veg": ["Dal", "Rice", "Roti", "Paneer Pulao", "Raita", "Sweet"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Pulao", "Raita", "Sweet"],
      },
      "dinner": {
        "veg": ["Dal", "Rice", "Roti", "Paneer Butter Masala", "Curd"],
        "nonVeg": ["Dal", "Rice", "Roti", "Chicken Masala", "Curd"],
      },
    },
  },
};
