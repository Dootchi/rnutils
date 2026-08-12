package com.bytedance.sdk.openadsdk.mediation.rn;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

final class ReadableMapUtils {
  private ReadableMapUtils() {}

  static boolean getBooleanOrDefault(ReadableMap map, String key, boolean fallback) {
    return map.hasKey(key) && !map.isNull(key) ? map.getBoolean(key) : fallback;
  }

  @Nullable
  static String getStringOrNull(ReadableMap map, String key) {
    return map.hasKey(key) && !map.isNull(key) ? map.getString(key) : null;
  }

  @Nullable
  static ReadableMap getMapOrNull(ReadableMap map, String key) {
    return map.hasKey(key) && !map.isNull(key) ? map.getMap(key) : null;
  }

  @Nullable
  static ReadableArray getArrayOrNull(ReadableMap map, String key) {
    return map.hasKey(key) && !map.isNull(key) ? map.getArray(key) : null;
  }

  @Nullable
  static Integer getIntOrNull(ReadableMap map, String key) {
    return map.hasKey(key) && !map.isNull(key) ? map.getInt(key) : null;
  }

  static List<String> toStringList(ReadableArray array) {
    List<String> values = new ArrayList<>();
    for (int index = 0; index < array.size(); index += 1) {
      if (array.getType(index) == ReadableType.String) {
        String value = array.getString(index);
        if (value != null) {
          values.add(value);
        }
      }
    }
    return values;
  }

  static Map<String, String> toStringMap(ReadableMap map) {
    Map<String, String> values = new HashMap<>();
    ReadableMapKeySetIterator iterator = map.keySetIterator();
    while (iterator.hasNextKey()) {
      String key = iterator.nextKey();
      if (map.getType(key) != ReadableType.String) {
        continue;
      }

      String value = map.getString(key);
      if (value != null) {
        values.put(key, value);
      }
    }
    return values;
  }
}
