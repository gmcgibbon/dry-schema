RSpec.describe Dry::Schema, 'types specs' do
  context 'single type spec without rules' do
    subject(:schema) do
      Dry::Schema.form do
        required(:age, :int)
      end
    end

    it 'uses form coercion' do
      expect(schema.('age' => '19').to_h).to eql(age: 19)
    end
  end

  context 'single type spec with rules' do
    subject(:schema) do
      Dry::Schema.form do
        required(:age, :int).value(:int?, gt?: 18)
      end
    end

    it 'applies rules to coerced value' do
      expect(schema.(age: 19).messages).to be_empty
      expect(schema.(age: 18).messages).to eql(age: ['must be greater than 18'])
    end
  end

  context 'single type spec with an array' do
    subject(:schema) do
      Dry::Schema.form do
        required(:nums, array[:int])
      end
    end

    it 'uses form coercion' do
      expect(schema.(nums: %w(1 2 3)).to_h).to eql(nums: [1, 2, 3])
    end
  end

  context 'sum type spec without rules' do
    subject(:schema) do
      Dry::Schema.form do
        required(:age, [:nil, :int])
      end
    end

    it 'uses form coercion' do
      expect(schema.('age' => '19').to_h).to eql(age: 19)
      expect(schema.('age' => '').to_h).to eql(age: nil)
    end
  end

  context 'sum type spec with rules' do
    subject(:schema) do
      Dry::Schema.form do
        required(:age, [:nil, :int]).maybe(:int?, gt?: 18)
      end
    end

    it 'applies rules to coerced value' do
      expect(schema.(age: nil).messages).to be_empty
      expect(schema.(age: 19).messages).to be_empty
      expect(schema.(age: 18).messages).to eql(age: ['must be greater than 18'])
    end
  end

  context 'using a type object' do
    subject(:schema) do
      Dry::Schema.form do
        required(:age, Types::Params::Nil | Types::Params::Integer)
      end
    end

    it 'uses form coercion' do
      expect(schema.('age' => '').to_h).to eql(age: nil)
      expect(schema.('age' => '19').to_h).to eql(age: 19)
    end
  end

  context 'nested schema' do
    subject(:schema) do
      Dry::Schema.form do
        required(:user, :hash).schema do
          required(:email, :string)
          required(:age, :int)

          required(:address, :hash).schema do
            required(:street, :string)
            required(:city, :string)
            required(:zipcode, :string)

            required(:location, :hash).schema do
              required(:lat, :float)
              required(:lng, :float)
            end
          end
        end
      end
    end

    it 'uses form coercion for nested input' do
      input = {
        'user' => {
          'email' => 'jane@doe.org',
          'age' => '21',
          'address' => {
            'street' => 'Street 1',
            'city' => 'NYC',
            'zipcode' => '1234',
            'location' => { 'lat' => '1.23', 'lng' => '4.56' }
          }
        }
      }

      expect(schema.(input).to_h).to eql(
        user:  {
          email: 'jane@doe.org',
          age: 21,
          address: {
            street: 'Street 1',
            city: 'NYC',
            zipcode:  '1234',
            location: { lat: 1.23, lng: 4.56 }
          }
        }
      )
    end
  end

  context 'nested schema with arrays' do
    subject(:schema) do
      Dry::Schema.form do
        required(:song, :hash).value(:hash?).schema do
          required(:title, :string)

          required(:tags, :array).value(:array?).each do
            schema do
              required(:name, :string).value(:str?)
            end
          end
        end
      end
    end

    it 'fails to coerce gracefuly' do
      result = schema.(song: nil)

      expect(result.messages).to eql(song: ['must be a hash'])
      expect(result.to_h).to eql(song: nil)

      result = schema.(song: { tags: nil })

      expect(result.messages).to eql(song: { title: ['is missing'], tags: ['must be an array'] })
      expect(result.to_h).to eql(song: { tags: nil })
    end

    it 'uses form coercion for nested input' do
      input = {
        'song' => {
          'title' => 'dry-rb is awesome lala',
          'tags' => [{ 'name' => 'red' }, { 'name' => 'blue' }]
        }
      }

      expect(schema.(input).to_h).to eql(
        song: {
          title: 'dry-rb is awesome lala',
          tags: [{ name: 'red' }, { name: 'blue' }]
        }
      )
    end
  end
end
