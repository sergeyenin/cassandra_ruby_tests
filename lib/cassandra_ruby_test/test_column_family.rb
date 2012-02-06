class TestColumnFamily < RightSupport::DB::CassandraModel
  self.keyspace = "CassandraRubyTest"
  self.column_family = "TestColumnFamily"

  MAX_DETAIL_SIZE = 1024 * 1024
  TRUNCATE_MSG = "\n\n***** RECORD TRUNCATED *****\n\n"

  def self.append(key, value, offset=0)
    unless offset
      offset =
        if detail = TestColumnFamily.get(key)
          max = detail.attributes.keys.max
          max.to_i + detail[max].size
        else
          0
        end
    end

    if value.size > MAX_DETAIL_SIZE
      value = value[0..MAX_DETAIL_SIZE]
      #logger.info("Limiting detail size to #{MAX_DETAIL_SIZE} for key: #{key}")
    end

    if offset > MAX_DETAIL_SIZE
      #logger.info("Truncating detail (requested offset = #{offset}) for key: #{key}")
      offset = MAX_DETAIL_SIZE
      value  = TRUNCATE_MSG + value
    end
    #logger.info("Appending detail size #{value.size} for key: #{key}")
    TestColumnFamily.insert(key, { offset => value })
  end

  def full_detail
    data = attributes.values.join('')
    unless attributes.keys.first.to_i == 0
      s3_data = S3Helper.get(self.key)
      return s3_data + data unless s3_data.nil?
    end
    data
  end
end