T? accessDeeplyNestedKey<T>(final Map<String, dynamic> obj, final String path) {
  dynamic result = obj;

  for (final subPath in path.split(".")) {
    if (result.containsKey(subPath)) {
      result = result[subPath];
    } else {
      return null;
    }
  }

  return result as T;
}

const adnk = accessDeeplyNestedKey;
