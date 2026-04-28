class MathUtils {
  static bool isPrime(int n) {
    if (n <= 1) return false;
    if (n <= 3) return true;
    if (n % 2 == 0 || n % 3 == 0) return false;
    for (int i = 5; i * i <= n; i += 6) {
      if (n % i == 0 || n % (i + 2) == 0) return false;
    }
    return true;
  }

  static List<int> getPrimeFactors(int n) {
    List<int> factors = [];
    int temp = n;
    int d = 2;
    while (temp > 1) {
      while (temp % d == 0) {
        factors.add(d);
        temp ~/= d;
      }
      d++;
      if (d * d > temp) {
        if (temp > 1) {
          factors.add(temp);
          break;
        }
      }
    }
    return factors;
  }

  static List<int> getAllFactors(int n) {
    Set<int> factors = {};
    for (int i = 2; i * i <= n; i++) {
      if (n % i == 0) {
        factors.add(i);
        int partner = n ~/ i;
        if (partner != n && partner != 1) {
          factors.add(partner);
        }
      }
    }
    List<int> result = factors.toList();
    result.sort();
    return result;
  }
}
