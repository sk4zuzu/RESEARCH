package lh.poc;

import org.redisson.Redisson;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;

public class Test1 {
    public static void main(final String[] args) {
        final String REDIS_IP4 = System.getenv().get("REDIS_IP4");

        Config config = new Config();
        config.useSentinelServers()
            .setMasterName("mymaster")
            .addSentinelAddress("redis://" + REDIS_IP4 + ":26379")
            .setPassword("asd123");

        RedissonClient client = Redisson.create(config);
  }
}
